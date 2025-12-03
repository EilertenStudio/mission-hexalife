'use client'

import {redirect, useSearchParams} from "next/navigation";

export default function StoryPage() {
  const searchParams = new URLSearchParams(useSearchParams());

  const branch = searchParams.get("branch");
  searchParams.delete("branch");

  if (branch) {
    redirect(`/story/blob/${branch}/index.html`)
  } else {
    redirect(`/story/blob/no-build`)
  }

  return <></>;
}