'use client'

import "./page.css"

export interface GamePageProps {
  branch: string,
}

export default function GamePage(p: GamePageProps) {
  return (
    <iframe src={`/blob/game/${p.branch}/index.html`}/>
  );
}