'use client'

import './page.css'

import {addBasePath} from "next/dist/client/add-base-path";

export interface StoryPageProps {
  version: string;
  debug?: boolean;
}

export default function StoryPage(p: StoryPageProps) {
  const sourceParams = new URLSearchParams();
  const sourceLink = addBasePath(`/lib/story/index.html`);

  sourceParams.append("story", addBasePath(`/blob/story/${p.version}/story.json`))

  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p className={"w-fit"}>{sourceLink}</p>) : null}
      <iframe src={`${sourceLink}?${sourceParams.toString()}`}/>
    </div>
  );
}