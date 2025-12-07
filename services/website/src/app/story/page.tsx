'use client'

import './page.css'

import {addBasePath} from "next/dist/client/add-base-path";
import {useEffect, useState} from "react";

export interface StoryPageProps {
  version: string;
  debug?: boolean;
}

export default function StoryPage(p: StoryPageProps) {
  // const sourceLink = addBasePath(`/blob/story/${p.version}/index.html`);
  const sourceLink = addBasePath(`/lib/story/index.html`);

  const [isClient, setIsClient] = useState(false)

  useEffect(() => {
    setIsClient(true)
  }, [])
  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p className={"w-fit"}>{sourceLink}</p>) : null}
      <iframe src={sourceLink}/>
    </div>
  );
}