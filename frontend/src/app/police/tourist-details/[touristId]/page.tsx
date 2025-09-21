import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
    Table, TableHeader, TableRow, TableHead, TableBody, TableCell,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { ShieldAlert } from "lucide-react";
import Link from "next/link";

// Generate static params for the dynamic route
export function generateStaticParams() {
  // Return an array of possible touristId values for static generation
  return [
    { touristId: 'SOS-001' },
    { touristId: 'SOS-002' },
    { touristId: 'SOS-003' },
    // Add more tourist IDs as needed
  ];
}

export default function Page({
    params,
}: {
    params: { touristId: string };
}) {
    const { touristId } = params;

    return (
        <div className="mx-auto max-w-7xl space-y-6 p-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                    <h1 className="text-2xl font-semibold tracking-tight">Tourist {touristId}</h1>
                    <p className="text-sm text-muted-foreground">Tourist Profile</p>
                </div>
                <div className="flex items-center gap-3">
                    <Badge className="rounded-3xl bg-emerald-100 text-emerald-900 ring-1 ring-emerald-200">
                        Active
                    </Badge>
                    <div className="hidden sm:flex gap-2">
                        <Link href="/police/tourist-details/SOS-001/fir">
                            <Button variant="destructive" size="sm">
                                <ShieldAlert className="h-4 w-4 mr-2" />E-FIR
                            </Button>
                        </Link>
                    </div>
                    <div className="hidden sm:flex gap-2">
                        <Link href="/police/live-alerts">
                            <Button size="sm" className="bg-zinc-400">
                                Decline
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>

            <Card className="bg-white border shadow-sm rounded-xl">
                <CardHeader>
                    <CardTitle className="text-base font-semibold">Basic Information</CardTitle>
                </CardHeader>
                <CardContent className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    <Field label="Name" value="Craig R" />
                    <Field label="Nationality" value="India" />
                    <Field label="Phone" value="+91 98765 43210" />
                    <Field label="Emergency Contact" value="+91 91234 56789" />
                    <Field label="Document ID" value="P1234567" />
                    <Field label="Trip Dates" value="Sep 8–12, 2025" />
                    <Field label="Itinerary" value="Mumbai" />
                    <Field label="Registered On" value="Sep 8, 2025" />
                </CardContent>
            </Card>

            <Card className="bg-white border shadow-sm rounded-xl overflow-hidden">
                <CardHeader className="flex items-center justify-between">
                    <CardTitle className="text-base font-semibold">Last Known Location</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">


                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <Field label="Timestamp" value="2025-09-09 15:42 IST" />
                        <Field label="Area" value="Guwahati, India" />
                    </div>

                    <div className="rounded-lg border overflow-x-auto">
                        <Table>
                            <TableHeader>
                                <TableRow className="bg-zinc-50 sticky top-0 z-10">
                                    <TableHead className="text-left p-3">Time</TableHead>
                                    <TableHead className="text-left p-3">Location</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody className="[&>tr:nth-child(odd)]:bg-zinc-50/50">
                                <TableRow className="hover:bg-zinc-100/70 transition-colors">
                                    <TableCell className="p-3">2025-09-09 15:42 IST</TableCell>
                                    <TableCell className="p-3">Restroom</TableCell>
                                </TableRow>
                                <TableRow className="hover:bg-zinc-100/70 transition-colors">
                                    <TableCell className="p-3">2025-09-09 15:38 IST</TableCell>
                                    <TableCell className="p-3">Cell Tower</TableCell>

                                </TableRow>
                            </TableBody>
                        </Table>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}

function Field({ label, value }: { label: string; value: string }) {
    return (
        <div className="space-y-1">
            <div className="text-xs text-muted-foreground">{label}</div>
            <div className="text-sm font-medium">{value}</div>
        </div>
    );
}
