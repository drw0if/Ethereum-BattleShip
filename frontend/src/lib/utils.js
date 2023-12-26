import { get } from 'svelte/store';
import { web3, contracts } from 'svelte-web3';

const decode_event = (event_name, log) => {
    const proposed_abi = get(contracts).BattleShip.events[event_name]().abi;
    const signature = get(web3).utils.sha3(proposed_abi.name + '(' + proposed_abi.inputs.map(x => x.type).join(',') + ')')

    if (log.topics[0] !== signature) {
        throw new Error('Event signature mismatch');
    }

    const data = get(web3).eth.abi.decodeLog(
        proposed_abi.inputs,
        log.data,
        log.topics.slice(1)
    );

    return data;
}

const compute_proof = (x, y) => {
    const hash = get(web3).utils.soliditySha3(x, y);
    return get(web3).utils.toBigInt(hash);
}

export { decode_event, compute_proof }