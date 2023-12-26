const GameStates = {};
[
    'SettingUp',
    'NotStarted',
    'WaitingForOpponent',
    'FeeNegotiation',
    'WaitingCommitment',
    'WaitingForMove',
    'WaitingForProof',
    'WaitingForReveal',
    'GameOver',

    'WaitingForReceipt',
].forEach((state, index) => (GameStates[state] = index));

const CONTRACT_ADDRESS = '0x5429c63b6DBcfddD8696e719DB48f2F8C4aE95F6';

export {
    GameStates,
    CONTRACT_ADDRESS,
}