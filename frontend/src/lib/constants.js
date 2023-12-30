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

const CONTRACT_ADDRESS = '0x977e50C6e323B3EbAd5EbfDdDB5b361374Cb91bC';

export {
    GameStates,
    CONTRACT_ADDRESS,
}