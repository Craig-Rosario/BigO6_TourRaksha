"use client";

import {
  Card, CardContent, CardHeader, CardTitle,
} from "@/components/ui/card";
import {
  Table, TableHeader, TableRow, TableHead, TableBody, TableCell,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import Link from "next/link";

function ratingColor(r: number) {
  if (r <= 2) return "text-red-600";
  if (r <= 4) return "text-amber-600";
  return "text-emerald-700";
}

export default function PoliceDashboard() {
  return (
    <div className="mx-auto max-w-7xl space-y-6 p-6">
      <h1 className="text-3xl font-semibold">Dashboard</h1>

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <Card className="bg-zinc-50">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Total Tourists</CardTitle>
          </CardHeader>
          <CardContent><div className="text-3xl font-semibold tracking-tight">45</div></CardContent>
        </Card>

        <Card className="bg-zinc-50">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Digital IDs Issued</CardTitle>
          </CardHeader>
          <CardContent><div className="text-3xl font-semibold tracking-tight">24</div></CardContent>
        </Card>

        <Card className="bg-zinc-50">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Active SOS</CardTitle>
          </CardHeader>
          <CardContent><div className="text-3xl font-semibold tracking-tight text-red-600">2</div></CardContent>
        </Card>

        <Card className="bg-zinc-50">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Open Alerts</CardTitle>
          </CardHeader>
          <CardContent><div className="text-3xl font-semibold tracking-tight text-amber-600">9</div></CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="overflow-hidden bg-zinc-50">
          <CardHeader className="py-4">
            <CardTitle className="text-xl">Live Alerts</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="rounded-lg border bg-white overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/50">
                    <TableHead className="w-[110px]">ID</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Location</TableHead>
                    <TableHead className="w-[140px]">Time</TableHead>
                    <TableHead className="w-[120px]">Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody className="[&>tr:nth-child(odd)]:bg-muted/30">
                  <TableRow className="hover:bg-zinc-100/70">
                    <TableCell>
                      <Link href={`/police/tourist-details/${"SOS-001"}`}>SOS-001</Link>
                    </TableCell>
                    <TableCell>Panic</TableCell>
                    <TableCell>Gate 3</TableCell>
                    <TableCell>16:05</TableCell>
                    <TableCell>
                      <Badge className="rounded-full bg-red-200 text-red-900">Critical</Badge>
                    </TableCell>
                  </TableRow>
                  <TableRow className="hover:bg-zinc-100/70">
                    <TableCell>
                      <Link href={`/police/tourist-details/${"A-102"}`}>A-102</Link>
                    </TableCell>
                    <TableCell>Crowd Spike</TableCell>
                    <TableCell>West Plaza</TableCell>
                    <TableCell>15:58</TableCell>
                    <TableCell>
                      <Badge className="rounded-full bg-red-200 text-red-900">Critical</Badge>
                    </TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>

        <Card className="overflow-hidden bg-zinc-50">
          <CardHeader className="py-4">
            <CardTitle className="text-xl">Recent Feedback</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="rounded-lg border bg-white overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/50">
                    <TableHead className="w-[90px]">Rating</TableHead>
                    <TableHead>Location</TableHead>
                    <TableHead className="w-[130px]">Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody className="[&>tr:nth-child(odd)]:bg-muted/30">
                  <TableRow className="hover:bg-zinc-100/70">
                    <TableCell>
                      <span className={`font-medium ${ratingColor(5)}`}>5★</span>
                    </TableCell>
                    <TableCell>Info Kiosk A</TableCell>
                    <TableCell>2025-09-09</TableCell>
                  </TableRow>
                  <TableRow className="hover:bg-zinc-100/70">
                    <TableCell>
                      <span className={`font-medium ${ratingColor(2)}`}>2★</span>
                    </TableCell>
                    <TableCell>Gate 3</TableCell>
                    <TableCell>2025-09-09</TableCell>
                  </TableRow>
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>

      </div>
    </div>
  );
}
