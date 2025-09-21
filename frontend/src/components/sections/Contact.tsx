"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Facebook, Twitter, Linkedin, Instagram, Github } from "lucide-react";
import TourRakshaLogo from "../../../public/images/TourRakshaLogo.png"
import Image from "next/image";

export default function Contact() {
  

  return (
    <section id="contact" className="bg-white text-zinc-900">


      <footer className="border-t border-zinc-200 bg-white">
        <div className="mx-auto max-w-7xl px-6 md:px-10 py-12">
          <div className="grid gap-10 md:grid-cols-3">
            <div>
              <div className="flex items-center space-x-2">
                <Image
                    src={TourRakshaLogo}
                    alt="Tourरक्षा Logo"
                    className="w-8 h-8"
                />                
              </div>
              <p className="mt-3 max-w-sm text-sm text-zinc-600">
                Real-time tourist safety: blockchain Digital ID, AI anomaly detection, geofencing alerts, and
                SOS routing to authorities and family.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-8 md:col-span-2">
              <div>
                <h4 className="text-sm font-semibold text-zinc-900">Sections</h4>
                <ul className="mt-3 space-y-2 text-sm text-zinc-600">
                  <li><a href="#" className="hover:text-zinc-900">Home</a></li>
                  <li><a href="#features" className="hover:text-zinc-900">Features</a></li>
                  <li><a href="#contact" className="hover:text-zinc-900">Contact</a></li>
                </ul>
              </div>
              <div>
                <h4 className="text-sm font-semibold text-zinc-900">Product</h4>
                <ul className="mt-3 space-y-2 text-sm text-zinc-600">
                  <li><a href="https://tour-raksha.vercel.app/" className="hover:text-zinc-900">Mobile App</a></li>
                  <li><a href="#" className="hover:text-zinc-900">Police Console</a></li>
                </ul>
              </div>
            </div>
          </div>

          <div className="mt-10 flex flex-col items-center justify-between gap-6 border-t border-zinc-200 pt-6 md:flex-row">
            <p className="text-xs text-zinc-500">© 2025 Tourरक्षा. All rights reserved.</p>
            <div className="flex items-center gap-3">
              <a href="https://github.com/OmLanke/BigO6" aria-label="Facebook" className="rounded-full border border-zinc-200 p-2 hover:bg-zinc-50">
                <Github className="h-4 w-4 text-zinc-700" />
              </a>
            </div>
          </div>
        </div>
      </footer>
    </section>
  );
}
