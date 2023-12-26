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

const CONTRACT_ADDRESS = '0x5A0E128d074CEbe8fcd46341C20EFc23F6Fdc759';

export {
    GameStates,
    CONTRACT_ADDRESS,
}