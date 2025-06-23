import React, { useContext, useEffect } from "react";
import { useAccount, useNetwork, useSigner } from "wagmi";
import { Contract } from "alchemy-sdk";
import { AppContext } from "../pages";
import { useGameSessionListener } from "../hooks/useGameSessionListener";
import Cell from "./Cell";
import {
  zeroAddress,
  contractAddress,
  chainidMap,
  abi,
} from "../components/constants";

export default function Board() {
  const { sessionId, setCells, setText, setDisabledCell, setCurrentChar } =
    useContext(AppContext);
  const { address } = useAccount();
  const { chain } = useNetwork();
  const { data: signer } = useSigner();

  const applyUpdate = async (gs) => {
    if (!chain || !signer) return;
    try {
      const contract = new Contract(
        contractAddress[chainidMap[chain.id]],
        abi,
        signer
      );
      const boardStatus = await contract.getBoardStatus(sessionId);
      const flat = boardStatus.map((v) => (v === 1 ? "X" : v === 2 ? "O" : ""));
      const newBoard = [[], [], []];
      flat.forEach((val, idx) => {
        const r = Math.floor(idx / 3),
          c = idx % 3;
        newBoard[r][c] = val;
      });
      setCells(newBoard);

      const { player_1: p1, player_2: p2, turn } = gs;

      const turnChar =
        turn.toLowerCase() === p1.toLowerCase()
          ? "X"
          : turn.toLowerCase() === p2.toLowerCase()
          ? "O"
          : "";

      const isMyTurn = turn.toLowerCase() === address.toLowerCase();

      if (gs.winner !== zeroAddress) {
        setText(
          gs.winner === address && gs.wonner !== zeroAddress
            ? "You Win!"
            : "You Lose…"
        );
        setDisabledCell(true);
      } else {
        if (isMyTurn) {
          setText(`Your turn (${turnChar})`);
        } else {
          setText(`Waiting: ${turnChar}'s turn`);
        }
        setCurrentChar(turnChar);
        setDisabledCell(!isMyTurn);
      }
    } catch (e) {
      console.error("applyUpdate failed", e);
    }
  };

  useEffect(() => {
    if (!sessionId || !chain || !signer) return;
    const contract = new Contract(
      contractAddress[chainidMap[chain.id]],
      abi,
      signer
    );
    contract
      .gameSessions(sessionId)
      .then(applyUpdate)
      .catch((e) => console.error("Initial fetch failed", e));
  }, [sessionId, chain, signer]);

  useGameSessionListener(sessionId, applyUpdate);

  return (
    <div
      style={{
        height: 395,
        width: 395,
        backgroundColor: "#fff",
        borderRadius: 10,
        display: "grid",
        gridTemplateColumns: "120px 120px 120px",
        gridGap: 10,
        padding: 10,
        alignItems: "center",
      }}
    >
      {[0, 1, 2].map((r) =>
        [0, 1, 2].map((c) => <Cell key={`${r}-${c}`} row={r} column={c} />)
      )}
    </div>
  );
}
