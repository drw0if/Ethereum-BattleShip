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

const CONTRACT_ADDRESS = '0xda51B54A4d679B377B7f042EC841f56929Aa3db9';

export {
    GameStates,
    CONTRACT_ADDRESS,
}