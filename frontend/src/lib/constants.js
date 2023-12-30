const GameStates = {};
[
    'SettingUp',
    'NotStarted',
    'WaitingForOpponent',
    'FeeNegotiation',
    'WaitingCommitment',
    'Game',
    'RevealBoard',
    'GameOver',

    'HallOfShame'
].forEach((state, index) => (GameStates[state] = index));

const CONTRACT_ADDRESS = '0xdD94F40fEAFAeE29644224C94F1F1ebdc700dCd4';

export {
    GameStates,
    CONTRACT_ADDRESS,
}