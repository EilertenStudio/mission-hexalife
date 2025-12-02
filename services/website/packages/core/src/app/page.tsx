'use client';

import {useSearchParams} from "next/navigation";
import GamePage from "@/app/game/page";
import StoryPage from "@/app/story/page";

export default function MainPage() {
  const searchParams = new URLSearchParams(useSearchParams());

  const type = searchParams.get("type");
  searchParams.delete("type");

  switch (type) {
    case "game":
      // redirect("/game?" + searchParams.toString());
      return <GamePage />
    case "story":
      // redirect("/story?" + searchParams.toString());
      return <StoryPage />
  }

  return <>Bad Request</>;
}