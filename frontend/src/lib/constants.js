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

const CONTRACT_ADDRESS = '0xB5284B74685Df67BADD8F6A9D54Af6382D88F11E';

export {
    GameStates,
    CONTRACT_ADDRESS,
}