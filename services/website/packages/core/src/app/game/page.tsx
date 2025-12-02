'use client'

import {redirect, useSearchParams} from "next/navigation";

export default function GamePage() {
  const searchParams = new URLSearchParams(useSearchParams());

  const branch = searchParams.get("branch");
  searchParams.delete("branch");

  if (branch) {
    redirect(`/game/blob/${branch}/index.html`)
  } else {
    redirect(`/game/blob/no-build`)
  }

  return <></>;
}