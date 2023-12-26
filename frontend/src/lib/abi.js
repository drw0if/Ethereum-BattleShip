export default [
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        }
      ],
      "name": "AccusationRequest",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "board",
          "type": "uint256"
        }
      ],
      "name": "BoardCommitted",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        }
      ],
      "name": "CheatingAttempt",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "EndOfGame",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "fee",
          "type": "uint256"
        }
      ],
      "name": "FeeAgreed",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "fee",
          "type": "uint256"
        }
      ],
      "name": "FeeProposed",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "winner",
          "type": "address"
        }
      ],
      "name": "GameOver",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "GameStarted",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint8",
          "name": "position",
          "type": "uint8"
        }
      ],
      "name": "Hit",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint8",
          "name": "position",
          "type": "uint8"
        }
      ],
      "name": "Miss",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint8",
          "name": "move",
          "type": "uint8"
        }
      ],
      "name": "MoveProposed",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "NewGame",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "address",
          "name": "player_id",
          "type": "address"
        }
      ],
      "name": "PlayerJoined",
      "type": "event"
    },
    {
      "inputs": [],
      "name": "new_game",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "join_game",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "join_random_game",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "fee",
          "type": "uint256"
        }
      ],
      "name": "propose_fee",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "board",
          "type": "uint256"
        }
      ],
      "name": "commit_board",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function",
      "payable": true
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "internalType": "uint8",
          "name": "move",
          "type": "uint8"
        }
      ],
      "name": "submit_move",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "internalType": "bool",
          "name": "has_ship",
          "type": "bool"
        },
        {
          "internalType": "uint256",
          "name": "nonce",
          "type": "uint256"
        },
        {
          "internalType": "uint256[6]",
          "name": "proof",
          "type": "uint256[6]"
        }
      ],
      "name": "submit_proof",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        },
        {
          "components": [
            {
              "internalType": "uint8",
              "name": "start_position",
              "type": "uint8"
            },
            {
              "internalType": "bool",
              "name": "direction",
              "type": "bool"
            }
          ],
          "internalType": "struct BattleShip.Ship[5]",
          "name": "ships",
          "type": "tuple[5]"
        },
        {
          "internalType": "uint256[64]",
          "name": "nonces",
          "type": "uint256[64]"
        }
      ],
      "name": "reveal_board",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "withdraw",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "make_accusation",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "get_game_state",
      "outputs": [
        {
          "internalType": "enum BattleShip.GameState",
          "name": "",
          "type": "uint8"
        }
      ],
      "stateMutability": "view",
      "type": "function",
      "constant": true
    },
    {
      "inputs": [],
      "name": "get_free_games_length",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function",
      "constant": true
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "game_id",
          "type": "uint256"
        }
      ],
      "name": "get_opponent",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function",
      "constant": true
    }
  ]

