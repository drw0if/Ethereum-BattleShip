const GameStates = {};
[
    'SettingUp',
    'NotStarted',
    'WaitingForOpponent',
    'FeeNegotiation',
    'WaitingCommitment',
    'Game',
    'WaitingForReveal',
    'GameOver',

    'WaitingForReceipt',
].forEach((state, index) => (GameStates[state] = index));

const CONTRACT_ADDRESS = '0x27a895D16743768B03De7991Fa81227B22B9E8E6';

export {
    GameStates,
    CONTRACT_ADDRESS,
}