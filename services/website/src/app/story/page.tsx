'use client'

import './page.css'

export interface StoryPageProps {
  branch: string,
}

export default function StoryPage(p: StoryPageProps) {
  return (
    <iframe src={`/blob/story/${p.branch}/index.html`}/>
  );
}