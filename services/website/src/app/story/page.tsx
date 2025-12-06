'use client'

import './page.css'
import {addBasePath} from 'next/dist/client/add-base-path';

export interface StoryPageProps {
  version: string;
  debug?: boolean;
}

export default function StoryPage(p: StoryPageProps) {
  const sourceLink = addBasePath(`/blob/story/${p.version}/index.html`);
  return (
    <div className={"w-full h-full"}>
      {p.debug ? (<p>{sourceLink}</p>) : null}
      <iframe src={sourceLink}/>
    </div>
  );
}