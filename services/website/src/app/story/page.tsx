'use client'

import './page.css'

import {addBasePath} from "next/dist/client/add-base-path";
import {useSearchParams} from "next/navigation";

export interface StoryPageProps {
  version: string;
  debug?: boolean;
}

export default function StoryPage(p: StoryPageProps) {
  const searchParams = useSearchParams();

  const version = p.version || searchParams.get("version") || "next";
  const debug = p.debug || searchParams.has("debug");

  const sourceParams = new URLSearchParams(useSearchParams());
  const sourceLink = addBasePath(`/lib/story/index.html`);

  sourceParams.append("story", addBasePath(`/blob/story/${version}/story.json`))

  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p className={"w-fit"}>{sourceLink}</p>) : null}
      <iframe src={`${sourceLink}?${sourceParams.toString()}`}/>
    </div>
  );
}