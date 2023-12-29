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

const CONTRACT_ADDRESS = '0x77D2E5Ab15bf38C7CEE32aB018460d62C2aE7013';

export {
    GameStates,
    CONTRACT_ADDRESS,
}