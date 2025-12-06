'use client';

import {redirect, useSearchParams} from "next/navigation";
import GamePage from "@/app/game/page";
import StoryPage from "@/app/story/page";

export default function MainPage() {
  const searchParams = useSearchParams();

  const type = searchParams.get("type");
  const version = searchParams.get("version") || "next";
  const debug = searchParams.has("debug");

  switch (type) {
    case "game":
      return <GamePage version={version} debug={debug}/>
    case "story":
      return <StoryPage version={version} debug={debug}/>
  }

  redirect("https://eilertenstudio.itch.io/mission-hexalife");
}