'use client';

import {redirect, useSearchParams} from "next/navigation";
import GamePage from "@/app/game/page";
import StoryPage from "@/app/story/page";

export default function MainPage() {
  const searchParams = useSearchParams();

  const type = searchParams.get("type");
  const debug = searchParams.has("debug");

  switch (type) {
    case "game":
      return <GamePage branch={searchParams.get("branch") || 'SNAPSHOT'} debug={debug}/>
    case "story":
      return <StoryPage branch={searchParams.get("branch") || 'SNAPSHOT'} debug={debug}/>
  }

  redirect("https://eilertenstudio.itch.io/mission-hexalife");
}