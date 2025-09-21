"use client";
import Image from "next/image";
import React from "react";
import TourRakshaLogo from "../../../public/images/TourRakshaLogo.png";
import { AuroraText } from "../magicui/aurora-text";
import Link from "next/link";

export default function Hero() {
  return (
    <section className="relative w-full min-h-screen bg-white flex items-center justify-center px-8 ">
      <span
        aria-hidden
        className="pointer-events-none absolute top-[-12%] right-[-14%] h-[36rem] w-[36rem]
                   rounded-full bg-[radial-gradient(closest-side,rgba(59,130,246,0.35),rgba(59,130,246,0.15)_60%,transparent_70%)]
                   blur-[160px]"
      />

      <span
        aria-hidden
        className="pointer-events-none absolute bottom-[-12%] left-[-14%] h-[36rem] w-[36rem]
             rounded-full bg-[radial-gradient(closest-side,rgba(59,130,246,0.35),rgba(59,130,246,0.15)_60%,transparent_70%)]
             blur-[160px]"
      />


      {/* Content */}
      <div className="relative z-10 max-w-7xl w-full grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
        <div className="flex flex-col gap-6">
          <h1 className="text-4xl md:text-6xl font-bold text-gray-900 leading-tight">
            Smart Tourist Safety <br /> with{" "}
            <span className="text-blue-600">
              <AuroraText>Tourरक्षा</AuroraText>
            </span>
          </h1>
          <p className="text-lg text-gray-600">
            AI, Geo-Fencing, and Blockchain powered digital IDs to keep tourists safe in real time.
          </p>
          <div className="flex gap-4">
            <Link href="/login">

              <button className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Get Started
              </button>
            </Link>
            <Link href="https://tour-raksha.vercel.app/">

              <button className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100">
                Open App
              </button>
            </Link>
          </div>
        </div>

        <div className="hidden md:flex justify-end">
          <Image
            src={TourRakshaLogo}
            alt="Tourरक्षा Logo"
            width={1800}
            height={1800}
            className="h-auto object-contain w-[680px] md:w-[980px] lg:w-[1200px] xl:w-[1400px] mb-16"
            priority
          />
        </div>
      </div>
    </section>
  );
}
