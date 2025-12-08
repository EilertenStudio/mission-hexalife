'use client'

import './page.css'

export interface StoryPageProps {
  debug?: boolean;
  week: number;
}

export default function StoryPage(p: StoryPageProps) {
  // const version = p.week;

  return (
    <div className={"w-full h-full"}>
      No content here yet
      {/*{p.debug ? (<p className={"w-fit"}>{sourceLink}</p>) : null}*/}
      {/*<iframe src={`${sourceLink}?${sourceParams.toString()}`}/>*/}
    </div>
  );
}