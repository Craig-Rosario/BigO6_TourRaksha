import Image from "next/image";
import Hero from "@/components/sections/Hero";
import { NavbarDemo } from "@/components/sections/Navbar";
import Features from "@/components/sections/Features";
import Contact from "@/components/sections/Contact";
import Tablet from "@/components/sections/Tablet";

export default function Home() {
  return (

    <div className="p-0 m-0">
      <NavbarDemo />
      <main className="p-0 m-0 overflow-x-hidden">
        <Hero />
        {/* <Tablet/> */}
        <Features/>
        <Contact/>
      </main>
    </div>

  );
}
