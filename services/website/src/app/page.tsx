'use client';

import {redirect, useSearchParams} from "next/navigation";
import GamePage from "@/app/game/page";
import StoryPage from "@/app/story/page";

export default function MainPage() {
  const searchParams = new URLSearchParams(useSearchParams());

  const type = searchParams.get("type");
  searchParams.delete("type");

  switch (type) {
    case "game":
      return <GamePage branch={searchParams.get("branch") || 'SNAPSHOT'}/>
    case "story":
      return <StoryPage branch={searchParams.get("branch") || 'SNAPSHOT'}/>
  }

  redirect("https://eilertenstudio.itch.io/mission-hexalife");
}