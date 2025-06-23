import { useContractEvent, useSigner, useNetwork } from "wagmi";
import { useEffect } from "react";
import { Contract } from "alchemy-sdk";
import { contractAddress, chainidMap, abi } from "../components/constants";

export function useGameSessionListener(sessionId, onUpdate) {
  const { chain } = useNetwork();
  const { data: signer } = useSigner();
  const enabled = Boolean(chain && sessionId && signer);
  const address = enabled ? contractAddress[chainidMap[chain.id]] : undefined;

  useEffect(() => {
    if (!enabled) return;
    const contract = new Contract(address, abi, signer);
    contract
      .gameSessions(sessionId)
      .then((gs) => {
        onUpdate(gs);
      })
      .catch((e) => console.error("gameSessions fetch failed", e));
  }, [enabled, address, signer, sessionId]);

  // subscribe to MessageSent (args: messageId, destSelector, receiver, gs, fees)
  useContractEvent({
    address,
    abi,
    eventName: "MessageSent",
    listener: (_mid, _dest, _recv, gs /*GameSession*/, _fees) => {
      if (enabled && gs.sessionId === sessionId) onUpdate(gs);
    },
    enabled,
  });

  // subscribe to MessageReceived (args: messageId, srcSelector, sender, gs)
  // gs - gameSessions
  useContractEvent({
    address,
    abi,
    eventName: "MessageReceived",
    listener: (_mid, _src, _snd, gs) => {
      if (enabled && gs.sessionId === sessionId) onUpdate(gs);
    },
    enabled,
  });
}
