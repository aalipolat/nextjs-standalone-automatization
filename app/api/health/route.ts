import { NextResponse } from "next/server";

export async function GET(): Promise<NextResponse> {
  try {
    return NextResponse.json(
      {
        status: "ok",
        timestamp: new Date().toISOString(),
      },
      {
        status: 200,
      }
    );
  } catch (error) {
    return NextResponse.json(
      {
        status: "error",
        timestamp: new Date().toISOString(),
      },
      {
        status: 500,
      }
    );
  }
}
