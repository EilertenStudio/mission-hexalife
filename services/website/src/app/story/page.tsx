'use client'

import './page.css'
import {addBasePath} from 'next/dist/client/add-base-path';

export interface StoryPageProps {
  branch: string,
}

export default function StoryPage(p: StoryPageProps) {
  const sourceLink = addBasePath(`/blob/story/${p.branch}/index.html`);
  return (
    <div className={"w-full h-full"}>
      <p>{sourceLink}</p>
      <iframe src={sourceLink}/>
    </div>
  );
}