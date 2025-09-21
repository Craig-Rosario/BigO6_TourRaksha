import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import Image from "next/image";
import PrintButton from "@/components/PrintButton";
import TourRakshaLogo from "../../../../../../public/images/TourRakshaLogo.png";

// Generate static params for the dynamic route
export function generateStaticParams() {
  // Return an array of possible touristId values for static generation
  // For now, we'll include some sample values. You can customize this based on your needs.
  return [
    { touristId: 'SOS-001' },
    { touristId: 'SOS-002' },
    { touristId: 'SOS-003' },
    // Add more tourist IDs as needed
  ];
}


type FIR = {
  firNo?: string;
  year?: string;
  policeStation?: string;
  district?: string;

  occFrom?: string;         
  placeAddress?: string;     

  infoReceivedAt?: string;
  infoType?: "E-FIR";
  gdEntry?: string;

  cName?: string;           
  cPhone?: string;           
  cAddress?: string;         
  cIdDoc?: string;           


  ioNameRank?: string;
  preparedOn?: string;
};

const sample: FIR = {
  firNo: "110",
  year: "2025",
  policeStation: "Guwahati Police Station",
  district: "Kamrup Metropolitan district",

  placeAddress: "Gate 3, West Plaza, Guwahati",

  infoReceivedAt: "2025-09-09 16:05",
  infoType: "E-FIR",
  gdEntry: "GD 238/15:50",

  cName: "Devesh P",
  cPhone: "+91 98XXXXXX10",
  cAddress: "—",


  ioNameRank: "DS Sharma",
  preparedOn: "2025-09-09 18:30",
};

export default function FIRLayoutPage() {
  const data = sample; 

  return (
    <div className="mx-auto max-w-[850px] p-6 print:p-0">
      <div className="mb-4 flex justify-end gap-2 no-print">
        <Link href={`/police/tourist-details/${"SOS-001"}`}>
        
        <Button variant="outline">Back</Button>
        </Link>
        <PrintButton />
      </div>

      <Card className="bg-white border shadow-sm rounded-xl print:shadow-none print:border-0">
        <CardHeader className="pb-3">
          <div className="flex flex-col items-center gap-4">
            <div className="relative w-[120px] h-[120px] print:block">
              <Image
                src={TourRakshaLogo}
                alt="TourRaksha Logo"
                priority
                className="object-contain"
                fill
              />
            </div>
            <CardTitle className="text-lg font-semibold text-center">
              FIRST INFORMATION REPORT (FIR)
            </CardTitle>
          </div>
        </CardHeader>

        <CardContent className="space-y-5 text-sm">
          <Section title="Basic Information">
            <Row a="FIR No." av={data.firNo} b="Year" bv={data.year} />
            <Row a="Police Station" av={data.policeStation} b="District" bv={data.district} />
            <Row a="Date/Time of Occurrence" av={data.occFrom} b="Location" bv={data.placeAddress} />
            <Row a="Complainant Name" av={data.cName} b="Phone" bv={data.cPhone} />
          </Section>

          <Section title="Incident Intake">
            <Row a="Information Received At" av={data.infoReceivedAt} b="Type of Information" bv={data.infoType || ""} />
            <RowFull a="GD Entry No./Time" av={data.gdEntry} />
          </Section>



          <Section title="Officer & Signatures">
            <Row a="Investigating Officer (Name/Rank)" av={data.ioNameRank} b="Prepared On" bv={data.preparedOn} />
            <div className="grid grid-cols-2 gap-6 mt-2">
            </div>
          </Section>
        </CardContent>
      </Card>

      {/* Print styles using dangerouslySetInnerHTML for server-side compatibility */}
      <style dangerouslySetInnerHTML={{
        __html: `
          @media print {
            .no-print { display: none !important; }
            @page { 
              size: A4; 
              margin: 12mm; 
            }
            html, body { 
              background: white;
              height: 100%;
              margin: 0 !important;
              padding: 0 !important;
            }
            main, .main-content {
              padding: 0 !important;
              margin: 0 !important;
            }
            img {
              print-color-adjust: exact;
              -webkit-print-color-adjust: exact;
            }
            nav, header, footer {
              display: none !important;
            }
          }
        `
      }} />
    </div>
  );
}


function Section({ title, children }: React.PropsWithChildren<{ title: string }>) {
  return (
    <section className="rounded-lg border p-3">
      <h2 className="text-xs font-semibold mb-2">{title}</h2>
      <div className="[&>div+div]:mt-2">{children}</div>
    </section>
  );
}

function Row({
  a, av, b, bv,
}: { a: string; av?: string; b: string; bv?: string }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <KV label={a} value={av} />
      <KV label={b} value={bv} />
    </div>
  );
}

function RowFull({ a, av, large }: { a: string; av?: string; large?: boolean }) {
  return (
    <div className="grid grid-cols-1">
      <KV label={a} value={av} large={large} />
    </div>
  );
}

function KV({ label, value, large }: { label: string; value?: string; large?: boolean }) {
  return (
    <div className="space-y-1">
      <div className="text-[11px] text-muted-foreground">{label}</div>
      <div
        className={`rounded-md border bg-white px-2 py-1 whitespace-pre-wrap ${
          large ? "min-h-[96px]" : "min-h-[40px]"
        }`}
      >
        {value || "\u00A0"}
      </div>
    </div>
  );
}

function Sig({ label }: { label: string }) {
  return (
    <div className="space-y-1">
      <div className="min-h-[40px] rounded-md border bg-white" />
      <div className="text-[11px] text-muted-foreground">{label}</div>
    </div>
  );
}
