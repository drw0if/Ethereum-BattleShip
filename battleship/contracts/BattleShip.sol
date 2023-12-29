// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/*
    The board is fixed to 8x8
    with the following pieces:
    - 1x Aircraft Carrier (5 squares)
    - 1x Battleship (4 squares)
    - 1x Cruiser (3 squares)
    - 2x Destroyers (2 squares)

    So we can terminate the game when:
    - 1 player has 16 hits
    - all positions have been revealed

    Merkle proof for a 64 position board (8x8):
    - actual position state
    - nonce used to generate the hash
    - 6 hashes
    - Merkle Hash (already stored in the contract)
 */

contract BattleShip {
    uint8 private constant NO_MOVE = 255;
    uint8 private constant MAX_HIT = 1;//16;
    uint8 private constant MAX_ROUNDS = 64;

    enum GameState {
        // Game created but waiting for the second player to join
        WaitingForOpponent,
        // Players joined the game but need to agree on the fee
        FeeNegotiation,
        // Players agreed on the fee and need to commit the board
        WaitingCommitment,
        // Players committed the board and now the game starts
        WaitingForMove,
        // Players must submit Merkle proof in order to prove the move result
        WaitingForProof,
        // Game ended and now player must reveal the board
        WaitingForReveal,
        // Game ended and now we have a winner
        GameOver
    }

    struct Ship {
        uint8 start_position;
        // true if horizontal, false if vertical
        bool is_horizontal;
    }

    struct Player {
        address user_id;
        // Used to implement the fee negotiation, then to store the actual fee
        uint256 proposed_fee;
        // Used to implement the board commitment and check at the end
        uint256 committed_board;
        // Used to implements accusation
        bool accused; // if true the player has been accused of leaving
        uint256 accused_at; // represents the time when the player has been accused
        // Used to store revealed board status and check at the end
        // bitmap used to store the revealed positions
        uint64 revealed_positions;
        // bitmap used to store the actual hit
        // only the actual bit at 1 in
        // revealed_positions & position_status
        // are the actual hits
        uint64 position_status;
        uint8 hits;
        // Used to implement the move submission
        uint8 move;
        // Used to implement both the move reveal and the board reveal
        bool revealed;
        bool withdrawed;
    }

    struct Game {
        uint256 game_id;
        GameState game_state;
        Player A;
        Player B;
        uint256 position_in_games_list;
        uint8 rounds_elapsed;
        address winner;
    }

    // Events to notify frontend
    event NewGame(uint256 game_id);
    event PlayerJoined(uint256 game_id, address player_id);
    event FeeProposed(uint256 game_id, address player_id, uint256 fee);
    event FeeAgreed(uint256 game_id, uint256 fee);
    event BoardCommitted(uint256 game_id, address player_id, uint256 board);
    event GameStarted(uint256 game_id);
    event MoveProposed(uint256 game_id, address player_id, uint8 move);
    event CheatingAttempt(uint256 game_id, address player_id);
    event Hit(uint256 game_id, address player_id, uint8 position);
    event Miss(uint256 game_id, address player_id, uint8 position);
    event NextRound(uint256 game_id);
    event EndOfGame(uint256 game_id);
    event GameOver(uint256 game_id, address winner);
    event AccusationRequest(uint256 game_id, address player_id);
    event AccusationElapsed(uint256 game_id, address player_id);
    event AccusationInPlace(uint256 game_id);

    // Collects actual games data, used for the game evolution
    mapping(uint256 => Game) private id2game;
    // Collects games which are pending for players to join
    // used for random matchmaking and game join
    uint256[] private free_games;
    uint256 private free_games_count;

    // NB: public because it is both used by the frontend and the contract itself
    function new_game() public {
        uint256 game_id = uint256(
            keccak256(abi.encodePacked(block.number - 1))
        );

        require(
            id2game[game_id].game_id == 0,
            "Can't create a new game at the moment, retry"
        );

        Game storage game = id2game[game_id];
        game.game_id = game_id;
        game.game_state = GameState.WaitingForOpponent;
        game.position_in_games_list = free_games_count;
        if (free_games_count == free_games.length) {
            free_games.push(game_id);
        } else {
            free_games[free_games_count] = game_id;
        }
        free_games_count++;

        game.A.user_id = msg.sender;

        emit NewGame(game_id);
    }

    // NB: public because it is both used by the frontend and the contract itself
    function join_game(uint256 game_id) public {
        require(id2game[game_id].game_id != 0, "Game does not exist");

        Game storage current_game = id2game[game_id];
        require(
            current_game.A.user_id != msg.sender,
            "You are already in this game"
        );

        // Remove the game from the list of available games
        if (free_games_count == 1) {
            // if only one element, just remove it
            delete free_games[0];
            free_games_count--;
        } else {
            // otherwise swap the current game with the last one
            // and then remove the last one and update it's position
            // in the list
            uint256 current_position = current_game.position_in_games_list;
            uint256 last_position = free_games_count - 1;
            uint256 last_game_id = free_games[last_position];

            free_games[current_position] = last_game_id;
            id2game[last_game_id].position_in_games_list = current_position;
            delete free_games[last_position];
            free_games_count--;
        }

        // Update game infos
        // Assign the opponet player
        current_game.B.user_id = msg.sender;

        // Move game to fee negotiation
        current_game.game_state = GameState.FeeNegotiation;

        emit PlayerJoined(game_id, msg.sender);
    }

    // If no game exists just create one
    // otherwise join random game
    // then returns the game_id
    // and a boolean to indicate if the game is new or not
    function join_random_game() external {
        if (free_games_count == 0) {
            new_game();
        } else {
            // make choice at random
            uint256 random_index = uint256(
                keccak256(abi.encodePacked(block.number - 1))
            );

            uint256 game_id = free_games[random_index % free_games_count];
            join_game(game_id);
        }
    }

    modifier player_in_game(uint256 game_id) {
        // Check that the game exists
        require(id2game[game_id].game_id != 0, "Game does not exist");

        // Check that user is in the game
        require(
            id2game[game_id].A.user_id == msg.sender ||
                id2game[game_id].B.user_id == msg.sender,
            "You are not in this game"
        );
        _;
    }

    modifier check_game_state(uint256 game_id, GameState game_state) {
        // Check that the game is in the correct state
        require(
            id2game[game_id].game_state == game_state,
            "Game is not in the correct state"
        );
        _;
    }

    // Propose fee until both players agree on the same fee
    function propose_fee(
        uint256 game_id,
        uint256 fee
    )
        external
        player_in_game(game_id)
        check_game_state(game_id, GameState.FeeNegotiation)
    {
        Game storage current_game = id2game[game_id];

        // Update fee proposal
        if (current_game.A.user_id == msg.sender) {
            current_game.A.proposed_fee = fee;
        } else {
            current_game.B.proposed_fee = fee;
        }

        // Manage notification to frontend and game state
        // Both players agreed on the fee
        if (current_game.A.proposed_fee == current_game.B.proposed_fee) {
            current_game.game_state = GameState.WaitingCommitment;
            emit FeeAgreed(game_id, fee);
        }
        // Otherwise just notify the frontend to continue the negotiation
        else {
            emit FeeProposed(game_id, msg.sender, fee);
        }
    }

    function commit_board(
        uint256 game_id,
        uint256 board
    )
        external
        payable
        player_in_game(game_id)
        check_game_state(game_id, GameState.WaitingCommitment)
    {
        Game storage current_game = id2game[game_id];

        Player storage player = (current_game.A.user_id == msg.sender)
            ? current_game.A
            : current_game.B;

        // Check that user did not already commit the board
        // otherwise it would double pay
        require(player.committed_board == 0, "You already committed the board");

        // Check that the fee has been paid
        // proposed_fee SHOULD be the same at this point
        require(
            msg.value == player.proposed_fee,
            "You must pay the fee to commit the board"
        );

        // Update committed board
        player.committed_board = board;

        // Manage notification to frontend and game state
        // Both players committed the board and payed the fee
        if (
            current_game.A.committed_board != 0 &&
            current_game.B.committed_board != 0
        ) {
            current_game.game_state = GameState.WaitingForMove;
            current_game.A.move = current_game.B.move = NO_MOVE;
            emit BoardCommitted(game_id, msg.sender, board);
            emit GameStarted(game_id);
        }
        // Otherwise just notify the frontend to continue wait for the other player
        else {
            emit BoardCommitted(game_id, msg.sender, board);
        }
    }

    function submit_move(
        uint256 game_id,
        uint8 move
    )
        external
        player_in_game(game_id)
        check_game_state(game_id, GameState.WaitingForMove)
    {
        // Move must be in the range [0, 63] for a 8x8 board
        require(move < 64, "Invalid position");
        Game storage current_game = id2game[game_id];

        Player storage player;
        Player storage opponent;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
            opponent = current_game.B;
        } else {
            player = current_game.B;
            opponent = current_game.A;
        }

        // Check if user already proposed a move
        require(player.move == NO_MOVE, "You already proposed a move");

        // Check if positions has already been revealed
        require(
            (opponent.revealed_positions & (1 << move)) == 0,
            "Position already revealed"
        );

        if (try_to_clean_accusation(game_id, player)) {
            return;
        }

        // Update move
        player.move = move;

        emit MoveProposed(game_id, msg.sender, move);

        // Check if opponent already proposed a move
        if (opponent.move != NO_MOVE) {
            // move to reveal phase
            current_game.game_state = GameState.WaitingForProof;
        }
    }

    function submit_proof(
        uint256 game_id,
        bool has_ship,
        uint256 nonce,
        uint256[6] memory proof
    )
        external
        player_in_game(game_id)
        check_game_state(game_id, GameState.WaitingForProof)
    {
        // Check that the proof has the needed length
        require(
            proof.length == 6,
            "Invalid proof, it must be an array of 6 hashes"
        );

        Game storage current_game = id2game[game_id];

        Player storage player;
        Player storage opponent;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
            opponent = current_game.B;
        } else {
            player = current_game.B;
            opponent = current_game.A;
        }

        // check that the user has not already revealed the move
        require(!player.revealed, "You already revealed the move");

        // Check if the proof is valid
        if (
            !check_proof(
                opponent.move,
                has_ship,
                nonce,
                proof,
                player.committed_board
            )
        ) {
            // Cheating attempt: terminate the game and set the opponet as the winner
            current_game.game_state = GameState.GameOver;
            current_game.winner = opponent.user_id;
            emit CheatingAttempt(game_id, msg.sender);
            emit GameOver(game_id, current_game.winner);
            return;
        }

        if (try_to_clean_accusation(game_id, player)) {
            return;
        }

        // Update revealed positions
        player.revealed_positions |= uint64(1 << opponent.move);

        // Update position status
        if (has_ship) {
            opponent.position_status |= uint64(1 << player.move);
            opponent.hits++;
            emit Hit(game_id, opponent.user_id, opponent.move);
        } else {
            emit Miss(game_id, opponent.user_id, opponent.move);
        }

        // set the move as revealed
        player.revealed = true;

        // Check if reveal phase is over
        if (opponent.revealed) {
            current_game.rounds_elapsed += 1;
            // Check if game is over
            if (
                opponent.hits == MAX_HIT ||
                player.hits == MAX_HIT ||
                current_game.rounds_elapsed == MAX_ROUNDS
            ) {
                // Game is over so user must reveal their boards
                current_game.game_state = GameState.WaitingForReveal;
                player.revealed = opponent.revealed = false;
                emit EndOfGame(game_id);
                return;
            }
            // Otherwise move to the next round
            current_game.game_state = GameState.WaitingForMove;
            player.move = opponent.move = NO_MOVE;
            player.revealed = opponent.revealed = false;
            emit NextRound(game_id);
        }
    }

    function reveal_board(
        uint256 game_id,
        Ship[5] memory ships,
        uint256[64] memory nonces
    )
        external
        player_in_game(game_id)
        check_game_state(game_id, GameState.WaitingForReveal)
    {
        Game storage current_game = id2game[game_id];

        Player storage player;
        Player storage opponent;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
            opponent = current_game.B;
        } else {
            player = current_game.B;
            opponent = current_game.A;
        }

        // Check that the user has not already revealed the board
        require(!player.revealed, "You already revealed the board");

        // Check that the user passed the right number of nonces
        require(nonces.length == 64, "Invalid nonces length");

        require(ships.length == 5, "Invalid ships length");

        // If the board cannot be built, the user is cheating
        uint64 board = build_board(ships);

        // Check if ship placement is valid
        // and that the board is the same as the committed one
        if (
            board == 0 ||
            !check_board_proof(player.committed_board, board, nonces)
        ) {
            // Cheating attempt: terminate the game and set the opponet as the winner
            current_game.game_state = GameState.GameOver;
            current_game.winner = opponent.user_id;
            emit CheatingAttempt(game_id, msg.sender);
            emit GameOver(game_id, current_game.winner);
            return;
        }

        if (try_to_clean_accusation(game_id, player)) {
            return;
        }

        // Update revealed positions
        player.position_status = board;
        // Update user state to revealed
        player.revealed = true;

        // If both user revealed the board, the game is over
        if (opponent.revealed) {
            // Set winner
            if (player.hits > opponent.hits) {
                // player wins
                current_game.winner = player.user_id;
            } else if (opponent.hits > player.hits) {
                // opponent wins
                current_game.winner = opponent.user_id;
            } else {
                // draw
                current_game.winner = address(0);
            }
            current_game.game_state = GameState.GameOver;
            emit GameOver(game_id, current_game.winner);
        }
    }

    function try_to_clean_accusation(
        uint256 game_id,
        Player storage current_player
    ) private returns (bool) {
        // Check if player is under accusation
        if (current_player.accused) {
            // If response is under time limit, the accusation is retired
            if (current_player.accused_at + 5 < block.timestamp) {
                current_player.accused = false;
                current_player.accused_at = 0;
                return false;
            } else {
                // Otherwise the accusation is valid and the opponent wins
                Game storage current_game = id2game[game_id];
                current_game.game_state = GameState.GameOver;
                current_game.winner = current_player.user_id ==
                    current_game.A.user_id
                    ? current_game.B.user_id
                    : current_game.A.user_id;
                emit AccusationElapsed(game_id, current_game.winner);
                return true;
            }
        }

        return false;
    }

    function withdraw(
        uint256 game_id
    )
        external
        player_in_game(game_id)
        check_game_state(game_id, GameState.GameOver)
    {
        Game storage current_game = id2game[game_id];
        require(
            current_game.winner == msg.sender ||
                current_game.winner == address(0),
            "You are not the winner of this game"
        );

        Player storage player;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
        } else {
            player = current_game.B;
        }

        require(!player.withdrawed, "You already withdrawed");

        uint256 amount = current_game.A.proposed_fee;
        if (current_game.winner == address(0)) {
            amount <<= 1;
        }

        // Avoid reentrancy
        player.withdrawed = true;
        payable(msg.sender).transfer(amount);
    }

    function make_accusation(uint256 game_id) external player_in_game(game_id) {
        // Check that the game is either in the waiting for move or waiting for proof/reveal state
        Game storage current_game = id2game[game_id];

        require(
            current_game.game_state == GameState.WaitingForMove ||
                current_game.game_state == GameState.WaitingForProof ||
                current_game.game_state == GameState.WaitingForReveal,
            "Game is not in the correct state"
        );

        Player storage player;
        Player storage opponent;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
            opponent = current_game.B;
        } else {
            player = current_game.B;
            opponent = current_game.A;
        }

        // Check that the user is not currently under accusation
        require(
            !player.accused,
            "You are under accusation, can't make other moves"
        );

        // Check that the other player is not currently under accusation
        require(!opponent.accused, "Opponent is already under accusation");

        opponent.accused = true;
        opponent.accused_at = block.timestamp;
    }

    function check_accusation(
        uint256 game_id
    ) external player_in_game(game_id) {
        Game storage current_game = id2game[game_id];

        Player storage player;
        Player storage opponent;

        if (current_game.A.user_id == msg.sender) {
            player = current_game.A;
            opponent = current_game.B;
        } else {
            player = current_game.B;
            opponent = current_game.A;
        }

        // Check if player is under accusation
        require(opponent.accused, "Your opponent is not under accusation");

        // If opponent did not respond in time, the accusation is valid
        if (opponent.accused_at + 5 < block.timestamp) {
            current_game.game_state = GameState.GameOver;
            current_game.winner = player.user_id;
            emit AccusationElapsed(game_id, current_game.winner);
            return;
        }
        emit AccusationInPlace(game_id);
    }

    /* Utility functions */

    /* Assume that:
        - index in [0, 63]
        - proof.length == 6
    */
    function check_proof(
        uint8 index,
        bool has_ship,
        uint256 nonce,
        uint256[6] memory proof,
        uint256 committed_board
    ) private pure returns (bool) {
        // build the leaf hash by hash(has_ship || nonce)
        uint256 previous_hash = uint256(
            keccak256(abi.encodePacked(has_ship, nonce))
        );

        for (uint8 i = 0; i < 6; i++) {
            if (index & 1 == 0) {
                // we are on the left side of the tree
                previous_hash = uint256(
                    keccak256(abi.encodePacked(previous_hash, proof[i]))
                );
            } else {
                // we are on the right side of the tree
                previous_hash = uint256(
                    keccak256(abi.encodePacked(proof[i], previous_hash))
                );
            }
            index = index >> 1;
        }

        return previous_hash == committed_board;
    }

    function check_board_proof(
        uint256 committed_board,
        uint64 board,
        uint256[64] memory nonces
    ) private pure returns (bool) {
        // Compute Merkle tree root
        uint8 i = 0;
        uint8 j = 0;
        uint8 actual_size = 64;

        uint256[64] memory tree;

        // Compute various hash(ship[i]  || nonces[i])
        for (i = 0; i < actual_size; i++) {
            tree[i] = uint256(
                keccak256(abi.encodePacked(((board >> i) & 1) == 1, nonces[i]))
            );
        }

        actual_size = actual_size >> 1;
        while (actual_size != 0) {
            for (i = j = 0; i < actual_size; i++) {
                tree[i] = uint256(
                    keccak256(abi.encodePacked(tree[j], tree[j + 1]))
                );
                j += 2;
            }
            actual_size = actual_size >> 1;
        }

        return tree[0] == committed_board;
    }

    function update_board(
        uint64 current_board,
        uint8 index,
        bool is_horizontal,
        uint8 ship_size
    ) private pure returns (uint64) {
        current_board |= uint64(1 << index);
        if (is_horizontal) {
            index += 1;
        } else {
            index += 8;
        }

        for (uint8 i = 1; i < ship_size; i++) {
            // if ship is horizontal we can't be at the start of the row
            if (is_horizontal && index & 0x7 == 0) {
                return 0;
            }
            // if ship is vertical we can't be over the last row
            if (!is_horizontal && index > 63) {
                return 0;
            }

            // If the bit is already set, it means that there is a collision
            if (current_board & uint64(1 << index) != 0) {
                return 0;
            }

            // Update board
            current_board |= uint64(1 << index);
            if (is_horizontal) {
                index += 1;
            } else {
                index += 8;
            }
        }

        return current_board;
    }

    function build_board(Ship[5] memory ships) private pure returns (uint64) {
        uint64 board = 0;
        uint8[5] memory sizes = [5, 4, 3, 2, 2];

        for (uint8 i = 0; i < 5; i++) {
            if(ships[i].start_position > 63) {
                return 0;
            }

            board = update_board(
                board,
                ships[i].start_position,
                ships[i].is_horizontal,
                sizes[i]
            );
            if (board == 0) {
                return 0;
            }
        }

        return board;
    }

    /* View functions */
    // Return GameState
    function get_game_state(uint256 game_id) external view returns (GameState) {
        require(id2game[game_id].game_id != 0, "Game does not exist");
        return id2game[game_id].game_state;
    }

    function get_free_games_length() external view returns (uint256) {
        return free_games_count;
    }

    function get_opponent(uint256 game_id) external view returns (address) {
        require(id2game[game_id].game_id != 0, "Game does not exist");
        Game storage current_game = id2game[game_id];
        if (current_game.A.user_id == msg.sender) {
            return current_game.B.user_id;
        } else {
            return current_game.A.user_id;
        }
    }
}
