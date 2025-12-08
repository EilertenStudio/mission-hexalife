'use client'

import "./page.css"
import {addBasePath} from "next/dist/client/add-base-path";
import {useSearchParams} from "next/navigation";

export interface GamePageProps {
  version: string;
  debug?: boolean;
}

export default function GamePage(p: GamePageProps) {
  const searchParams = useSearchParams();

  const version = p.version || searchParams.get("version") || "next";
  const debug = p.debug || searchParams.has("debug");

  const sourceLink = addBasePath(`/blob/game/${version}/index.html`);
  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p>{sourceLink}</p>) : null}
      <iframe src={sourceLink}/>
    </div>
  );
}