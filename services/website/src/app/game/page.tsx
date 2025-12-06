'use client'

import "./page.css"
import {addBasePath} from "next/dist/client/add-base-path";

export interface GamePageProps {
  branch: string;
  debug: boolean;
}

export default function GamePage(p: GamePageProps) {
  const sourceLink = addBasePath(`/blob/game/${p.branch}/index.html`);
  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p>{sourceLink}</p>) : null}
      <iframe src={sourceLink}/>
    </div>
  );
}