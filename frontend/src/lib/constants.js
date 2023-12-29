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

const CONTRACT_ADDRESS = '0x5C863f72914c22246e6E3e1D3F5A0Edf065b317E';

export {
    GameStates,
    CONTRACT_ADDRESS,
}