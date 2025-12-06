'use client'

import './page.css'
import {usePathname} from "next/navigation";

export interface StoryPageProps {
  branch: string,
}

export default function StoryPage(p: StoryPageProps) {
  const pathname = usePathname();

  return (
    <div className={"w-full h-full"}>
      <p>{pathname}</p>
      <iframe src={`/blob/story/${p.branch}/index.html`}/>
    </div>
  );
}