"use client";

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useState } from "react"
import { AlertCircle, Mail, Shield, CheckCircle, Loader2 } from "lucide-react"
import { Alert, AlertDescription } from "@/components/ui/alert"
import Link from "next/link"
type LoginFormProps = React.ComponentProps<"div">

export function LoginForm({ className, ...props }: LoginFormProps) {
  const [step, setStep] = useState<'email' | 'otp' | 'success'>('email');
  const [email, setEmail] = useState('');
  const [otp, setOtp] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');


  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    // Email validation regex
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    
    if (!emailRegex.test(email)) {
      setError('Please enter a valid email address');
      setIsLoading(false);
      return;
    }

    // Check if it's the test email
    if (email.toLowerCase() !== 'admin@tourraksha.com') {
      setError('Invalid email address. Please use the test email provided.');
      setIsLoading(false);
      return;
    }

    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Proceed to OTP step for the test email
    setStep('otp');
    setIsLoading(false);
  };

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    // Verify that OTP is exactly 123456
    if (otp !== '123952') {
      setError('Invalid OTP. Please use the test OTP provided.');
      setIsLoading(false);
      return;
    }

    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // OTP is correct (123456)
    setStep('success');
    // Redirect to dashboard after 2 seconds
    setTimeout(() => {
      window.location.href = '/police/dashboard';
    }, 2000);
    
    setIsLoading(false);
  };

  const handleResendOTP = async () => {
    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/users/auth/login/send-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email })
      });

      const data = await response.json();

      if (data.success) {
        setError('');
        // Show success message briefly
        setError('OTP resent successfully!');
        setTimeout(() => setError(''), 3000);
      } else {
        setError(data.message || 'Failed to resend OTP');
      }
    } catch {
      setError('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className={cn("flex flex-col gap-6", className)} {...props}>
      <div className="flex flex-col items-center gap-2 text-center">
        <div className="flex items-center gap-2 mb-4">
          <Shield className="h-8 w-8 text-blue-500" />
          <h1 className="text-3xl font-bold text-blue-500">Tourरक्षा</h1>
        </div>

        <h1 className="text-3xl font-semibold">
          {step === 'email' && 'Login to your account'}
          {step === 'otp' && 'Enter verification code'}
          {step === 'success' && 'Login successful!'}
        </h1>
        
        <p className="text-muted-foreground text-sm text-balance">
          {step === 'email' && 'Enter your email to receive a login code'}
          {step === 'otp' && `We sent a 6-digit code to ${email}`}
          {step === 'success' && 'Redirecting to your dashboard...'}
        </p>
      </div>

      {error && (
        <Alert variant={error.includes('successfully') ? "default" : "destructive"}>
          {error.includes('successfully') ? (
            <CheckCircle className="h-4 w-4" />
          ) : (
            <AlertCircle className="h-4 w-4" />
          )}
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {step === 'email' && (
        <form onSubmit={handleSendOTP} className="grid gap-6">
          <div>
            <p className="font-semibold text-center">(Test Email: admin@tourraksha.com)</p>
          </div>
          <div className="grid gap-3">
            <Label htmlFor="email">Email Address</Label>
            <div className="relative">
              <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="email"
                type="email"
                placeholder="enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="pl-10"
                required
                disabled={isLoading}
              />
            </div>
          </div>

          <Button 
            type="submit" 
            className="w-full bg-blue-500 hover:bg-blue-600" 
            disabled={isLoading || !email}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Sending Code...
              </>
            ) : (
              'Send Login Code'
            )}
          </Button>
        </form>
      )}

      {step === 'otp' && (
        <form onSubmit={handleVerifyOTP} className="grid gap-6">
          <div>
            <p className="font-semibold text-center">(Test OTP: 123952)</p>
          </div>
          <div className="grid gap-3">
            <Label htmlFor="otp">Verification Code</Label>
            <Input
              id="otp"
              type="text"
              placeholder="Enter 6-digit code"
              value={otp}
              onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
              maxLength={6}
              className="text-center text-2xl tracking-widest font-mono"
              required
              disabled={isLoading}
            />
          </div>

          <Button 
            type="submit" 
            className="w-full bg-blue-500 hover:bg-blue-600" 
            disabled={isLoading || otp.length !== 6}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Verifying...
              </>
            ) : (
              'Verify & Login'
            )}
          </Button>

          {/* <div className="text-center">
            <Button
              type="button"
              variant="ghost"
              className="text-sm text-muted-foreground"
              onClick={handleResendOTP}
              disabled={isLoading}
            >
              Didn&apos;t receive code? Resend
            </Button>
          </div> */}

          <div className="text-center">
            <Button
              type="button"
              variant="ghost"
              className="text-sm text-muted-foreground"
              onClick={() => {
                setStep('email');
                setOtp('');
                setError('');
              }}
            >
              ← Change email address
            </Button>
          </div>
        </form>
      )}

      {step === 'success' && (
        <div className="text-center py-8">
          <CheckCircle className="h-16 w-16 text-green-500 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-green-600 mb-2">Welcome back!</h3>
          <p className="text-muted-foreground mb-4">
            You have successfully logged into your account.
          </p>
          <div className="flex items-center justify-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" />
            Redirecting to dashboard...
          </div>
        </div>
      )}

    </div>
  )
}
