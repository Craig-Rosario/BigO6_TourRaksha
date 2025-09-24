import { PrismaClient } from "../generated/prisma/index.js";
import { generateOTP, storeOTP, verifyOTP, sendOTPEmail } from "../utils/emailService.js";

const prisma = new PrismaClient();

// Get all users
export const getUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      include: {
        trips: true,
        alerts: {
          where: { isResolved: false },
          orderBy: { createdAt: "desc" },
        },
        _count: {
          select: {
            trips: true,
            alerts: true,
            locations: true,
          },
        },
      },
    });
    res.json({
      success: true,
      data: users,
    });
  } catch (error) {
    console.error("Error fetching users:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch users",
      error: error.message,
    });
  }
};

// Get user by ID
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        trips: {
          orderBy: { createdAt: "desc" },
        },
        alerts: {
          orderBy: { createdAt: "desc" },
        },
        locations: {
          orderBy: { timestamp: "desc" },
          take: 10, // Last 10 locations
        },
        safetyScores: {
          orderBy: { createdAt: "desc" },
        },
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Error fetching user:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch user",
      error: error.message,
    });
  }
};

// Create new user
export const createUser = async (req, res) => {
  try {
    const userData = req.body;

    // Validate required fields
    if (!userData.email && !userData.phoneNumber) {
      return res.status(400).json({
        success: false,
        message: "Either email or phone number is required",
      });
    }

    const user = await prisma.user.create({
      data: userData,
    });

    res.status(201).json({
      success: true,
      data: user,
      message: "User created successfully",
    });
  } catch (error) {
    console.error("Error creating user:", error);

    // Handle unique constraint violation
    if (error.code === "P2002") {
      return res.status(400).json({
        success: false,
        message: "User with this email already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create user",
      error: error.message,
    });
  }
};

// Update user
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    // Process and validate update data
    const processedData = {};

    // Handle string fields
    const stringFields = ['name', 'phoneNumber', 'address', 'gender', 'bloodGroup', 
                         'languages', 'nationality', 'passportNumber', 'aadharCardUrl', 
                         'profileImageUrl', 'emergencyContactName', 'emergencyContactPhone', 
                         'emergencyContactRelation'];
    
    stringFields.forEach(field => {
      if (updateData[field] !== undefined) {
        processedData[field] = updateData[field] ? updateData[field].trim() : null;
      }
    });

    // Handle numeric fields
    if (updateData.height !== undefined) {
      processedData.height = updateData.height ? parseFloat(updateData.height) : null;
    }
    if (updateData.weight !== undefined) {
      processedData.weight = updateData.weight ? parseFloat(updateData.weight) : null;
    }

    // Handle boolean fields
    if (updateData.organDonor !== undefined) {
      processedData.organDonor = updateData.organDonor === true || updateData.organDonor === 'true';
    }
    if (updateData.isKycVerified !== undefined) {
      processedData.isKycVerified = updateData.isKycVerified === true || updateData.isKycVerified === 'true';
    }
    if (updateData.isActive !== undefined) {
      processedData.isActive = updateData.isActive === true || updateData.isActive === 'true';
    }

    // Handle date fields
    if (updateData.dateOfBirth !== undefined) {
      processedData.dateOfBirth = updateData.dateOfBirth ? new Date(updateData.dateOfBirth) : null;
    }

    // Validate email format if provided
    if (updateData.email !== undefined) {
      if (updateData.email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(updateData.email)) {
          return res.status(400).json({
            success: false,
            message: "Invalid email format"
          });
        }
        processedData.email = updateData.email.trim().toLowerCase();
      } else {
        processedData.email = null;
      }
    }

    // Validate phone number format if provided
    if (processedData.phoneNumber && !/^\+?[\d\s\-\(\)]+$/.test(processedData.phoneNumber)) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone number format"
      });
    }

    const user = await prisma.user.update({
      where: { id },
      data: processedData,
      include: {
        trips: {
          where: { status: "active" },
          take: 5
        },
        alerts: {
          where: { isResolved: false },
          take: 5
        },
        digitalID: true
      }
    });

    // Remove sensitive information
    const { password, ...userResponse } = user;

    res.json({
      success: true,
      data: userResponse,
      message: "User updated successfully",
    });
  } catch (error) {
    console.error("Error updating user:", error);

    if (error.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (error.code === "P2002") {
      return res.status(400).json({
        success: false,
        message: "Email or phone number already exists",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to update user",
      error: error.message,
    });
  }
};

// Delete user
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.user.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: "User deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting user:", error);

    if (error.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to delete user",
      error: error.message,
    });
  }
};

// Send OTP for email (unified for both login and registration)
export const sendEmailOTP = async (req, res) => {
  try {
    const { email, type } = req.body; // type can be 'login' or 'register'
    console.log(`Sending ${type} OTP to:`, email);

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required"
      });
    }

    if (!type || !['login', 'register'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: "Type must be either 'login' or 'register'"
      });
    }

    // Check if email is valid
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format"
      });
    }

    // Check if user exists with this email
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (type === 'register' && existingUser) {
      return res.status(400).json({
        success: false,
        message: "User with this email already exists"
      });
    }

    // For login type, allow both existing and new users
    // The verification step will handle user creation if needed

    // Generate and store OTP
    const otp = generateOTP();
    storeOTP(email, otp);

    // Send OTP via email
    await sendOTPEmail(email, otp, type === 'login' ? 'login' : 'registration');

    res.json({
      success: true,
      message: `${type === 'login' ? 'Login' : 'Registration'} OTP sent to email successfully`,
      data: { type }
    });
  } catch (error) {
    console.error("Error sending email OTP:", error);
    res.status(500).json({
      success: false,
      message: "Failed to send OTP",
      error: error.message
    });
  }
};

// Verify OTP (unified for both login and registration)
export const verifyEmailOTP = async (req, res) => {
  try {
    const { email, otp, type } = req.body; // type can be 'login' or 'register'

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Email and OTP are required"
      });
    }

    if (!type || !['login', 'register'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: "Type must be either 'login' or 'register'"
      });
    }

    // Verify the OTP
    const verification = verifyOTP(email, otp);

    if (!verification.valid) {
      return res.status(400).json({
        success: false,
        message: verification.message
      });
    }

    if (type === 'register') {
      // Check if user already exists
      let user = await prisma.user.findUnique({
        where: { email }
      });

      if (user) {
        // User already exists, check if profile is complete
        const isProfileComplete = user.name && user.phoneNumber && user.nationality;
        
        res.json({
          success: true,
          message: "Email verified successfully",
          data: { 
            userId: user.id, 
            email: user.email,
            type: 'register',
            requiresRegistration: !isProfileComplete
          }
        });
      } else {
        // Create a minimal user with just the email for registration
        user = await prisma.user.create({
          data: { email }
        });

        res.status(201).json({
          success: true,
          message: "Email verified successfully",
          data: { 
            userId: user.id, 
            email: user.email,
            type: 'register',
            requiresRegistration: true
          }
        });
      }
    } else if (type === 'login') {
      // Check if user exists
      let user = await prisma.user.findUnique({
        where: { email },
        include: {
          trips: {
            where: { status: "active" },
            orderBy: { createdAt: "desc" }
          },
          alerts: {
            where: { isResolved: false },
            orderBy: { createdAt: "desc" },
            take: 5
          },
          safetyScores: {
            orderBy: { createdAt: "desc" },
            take: 1
          }
        }
      });

      if (!user) {
        // User doesn't exist, create minimal user for registration flow
        user = await prisma.user.create({
          data: { email }
        });

        res.status(201).json({
          success: true,
          message: "Email verified successfully. Please complete your registration.",
          data: { 
            userId: user.id, 
            email: user.email,
            type: 'login',
            requiresRegistration: true
          }
        });
      } else {
        // Check if user profile is complete
        const isProfileComplete = user.name && user.phoneNumber && user.nationality;

        // Update last login timestamp
        await prisma.user.update({
          where: { id: user.id },
          data: { updatedAt: new Date() }
        });

        // Return user data (excluding sensitive information)
        const { password, ...userData } = user;

        res.json({
          success: true,
          message: "Login successful",
          data: {
            user: userData,
            type: 'login',
            requiresRegistration: !isProfileComplete,
            loginTime: new Date().toISOString()
          }
        });
      }
    }
  } catch (error) {
    console.error("Error verifying email OTP:", error);

    res.status(500).json({
      success: false,
      message: "Failed to verify email",
      error: error.message
    });
  }
};

// Complete user registration
export const completeUserRegistration = async (req, res) => {
  try {
    const { id } = req.params;
    const userData = req.body;

    // Validate required fields for complete registration
    const requiredFields = ['name', 'phoneNumber', 'nationality'];
    const missingFields = requiredFields.filter(field => !userData[field]?.trim());
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missingFields.join(', ')}`
      });
    }

    // Remove email from userData as we don't want to update the email
    const { email, ...updateData } = userData;

    // Prepare data for database update, ensuring proper data types
    const processedData = {
      ...updateData,
      // Ensure proper data types for numeric fields
      height: updateData.height ? parseFloat(updateData.height) : null,
      weight: updateData.weight ? parseFloat(updateData.weight) : null,
      
      // Ensure boolean fields are properly handled
      organDonor: updateData.organDonor === true || updateData.organDonor === 'true',
      isKycVerified: updateData.isKycVerified === true || updateData.isKycVerified === 'true',
      
      // Ensure date fields are properly handled
      dateOfBirth: updateData.dateOfBirth ? new Date(updateData.dateOfBirth) : null,
      
      // Map emergency contact fields to match schema
      emergencyContactName: updateData.emergencyContact || updateData.emergencyContactName,
      emergencyContactPhone: updateData.emergencyContactNumber || updateData.emergencyContactPhone,
      emergencyContactRelation: updateData.emergencyContactRelationship || updateData.emergencyContactRelation,
      
      // Remove the old field names to avoid conflicts
      emergencyContact: undefined,
      emergencyContactNumber: undefined,
      emergencyContactRelationship: undefined,
    };

    // Remove undefined values to avoid Prisma issues
    Object.keys(processedData).forEach(key => {
      if (processedData[key] === undefined) {
        delete processedData[key];
      }
    });

    console.log('Processing user registration data:', {
      userId: id,
      fields: Object.keys(processedData),
      hasDateOfBirth: !!processedData.dateOfBirth
    });

    // Update the user with the additional information
    const user = await prisma.user.update({
      where: { id },
      data: processedData,
      include: {
        digitalID: true
      }
    });

    // Create Digital ID if it doesn't exist
    let digitalID = user.digitalID;
    if (!digitalID) {
      const idNumber = `TID${Date.now()}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
      digitalID = await prisma.digitalID.create({
        data: {
          userId: user.id,
          idNumber,
          status: 'active'
        }
      });
    }

    // Return user data without sensitive information
    const { password, ...userResponse } = user;

    res.json({
      success: true,
      message: "User registration completed successfully",
      data: {
        ...userResponse,
        digitalID
      }
    });
  } catch (error) {
    console.error("Error completing user registration:", error);

    if (error.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    // Handle validation errors
    if (error.code === "P2002") {
      return res.status(400).json({
        success: false,
        message: "A user with this information already exists"
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to complete registration",
      error: error.message
    });
  }
};



// Upload Aadhar card (Mock KYC)
export const uploadAadharCard = async (req, res) => {
  try {
    const { id } = req.params;

    // Mock file upload - in real implementation, you'd handle file upload here
    const mockAadharUrl = `https://kyc-storage.example.com/aadhar/${id}_${Date.now()}.jpg`;

    const user = await prisma.user.update({
      where: { id },
      data: {
        aadharCardUrl: mockAadharUrl,
        isKycVerified: true, // Auto-verify for mock implementation
      },
    });

    res.json({
      success: true,
      data: user,
      message: "Aadhar card uploaded and KYC verified successfully",
    });
  } catch (error) {
    console.error("Error uploading Aadhar card:", error);

    if (error.code === "P2025") {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to upload Aadhar card",
      error: error.message,
    });
  }
};

// Get user's KYC status
export const getKycStatus = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        isKycVerified: true,
        aadharCardUrl: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.json({
      success: true,
      data: {
        isKycVerified: user.isKycVerified,
        hasAadharCard: !!user.aadharCardUrl,
        status: user.isKycVerified ? "verified" : "pending",
      },
    });
  } catch (error) {
    console.error("Error fetching KYC status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch KYC status",
      error: error.message,
    });
  }
};

// Get user profile completeness
export const getUserProfileCompleteness = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      include: {
        digitalID: true
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Define required fields for complete profile
    const requiredFields = {
      basic: ['name', 'email', 'phoneNumber', 'nationality'],
      emergency: ['emergencyContactName', 'emergencyContactPhone', 'emergencyContactRelation'],
      travel: ['passportNumber'],
      optional: ['dateOfBirth', 'gender', 'address']
    };

    const completeness = {
      basic: {
        completed: 0,
        total: requiredFields.basic.length,
        missing: []
      },
      emergency: {
        completed: 0,
        total: requiredFields.emergency.length,
        missing: []
      },
      travel: {
        completed: 0,
        total: requiredFields.travel.length,
        missing: []
      },
      optional: {
        completed: 0,
        total: requiredFields.optional.length,
        missing: []
      }
    };

    // Check each category
    Object.keys(requiredFields).forEach(category => {
      requiredFields[category].forEach(field => {
        if (user[field] && user[field].toString().trim()) {
          completeness[category].completed++;
        } else {
          completeness[category].missing.push(field);
        }
      });
    });

    const totalRequired = completeness.basic.total + completeness.emergency.total + completeness.travel.total;
    const totalCompleted = completeness.basic.completed + completeness.emergency.completed + completeness.travel.completed;
    const overallPercentage = Math.round((totalCompleted / totalRequired) * 100);

    const isProfileComplete = completeness.basic.missing.length === 0 && 
                             completeness.emergency.missing.length === 0 && 
                             completeness.travel.missing.length === 0;

    res.json({
      success: true,
      data: {
        isComplete: isProfileComplete,
        overallPercentage,
        completeness,
        hasDigitalID: !!user.digitalID,
        isKycVerified: user.isKycVerified,
      },
    });
  } catch (error) {
    console.error("Error checking profile completeness:", error);
    res.status(500).json({
      success: false,
      message: "Failed to check profile completeness",
      error: error.message,
    });
  }
};

// Validate user data
export const validateUserData = async (req, res) => {
  try {
    const userData = req.body;
    const errors = [];

    // Email validation
    if (userData.email) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(userData.email)) {
        errors.push({ field: 'email', message: 'Invalid email format' });
      }
    }

    // Phone validation
    if (userData.phoneNumber) {
      const phoneRegex = /^\+?[\d\s\-\(\)]+$/;
      if (!phoneRegex.test(userData.phoneNumber)) {
        errors.push({ field: 'phoneNumber', message: 'Invalid phone number format' });
      }
    }

    // Date of birth validation
    if (userData.dateOfBirth) {
      const dob = new Date(userData.dateOfBirth);
      const now = new Date();
      const age = now.getFullYear() - dob.getFullYear();
      
      if (isNaN(dob.getTime())) {
        errors.push({ field: 'dateOfBirth', message: 'Invalid date format' });
      } else if (age < 10 || age > 120) {
        errors.push({ field: 'dateOfBirth', message: 'Invalid age range' });
      }
    }

    // Height and weight validation
    if (userData.height && (userData.height < 30 || userData.height > 300)) {
      errors.push({ field: 'height', message: 'Height must be between 30 and 300 cm' });
    }

    if (userData.weight && (userData.weight < 10 || userData.weight > 500)) {
      errors.push({ field: 'weight', message: 'Weight must be between 10 and 500 kg' });
    }

    // Check if email/phone already exists
    if (userData.email || userData.phoneNumber) {
      const existingUser = await prisma.user.findFirst({
        where: {
          AND: [
            { id: { not: userData.id } }, // Exclude current user if updating
            {
              OR: [
                userData.email ? { email: userData.email } : {},
                userData.phoneNumber ? { phoneNumber: userData.phoneNumber } : {}
              ].filter(condition => Object.keys(condition).length > 0)
            }
          ]
        }
      });

      if (existingUser) {
        if (existingUser.email === userData.email) {
          errors.push({ field: 'email', message: 'Email already exists' });
        }
        if (existingUser.phoneNumber === userData.phoneNumber) {
          errors.push({ field: 'phoneNumber', message: 'Phone number already exists' });
        }
      }
    }

    res.json({
      success: true,
      isValid: errors.length === 0,
      errors
    });
  } catch (error) {
    console.error("Error validating user data:", error);
    res.status(500).json({
      success: false,
      message: "Failed to validate user data",
      error: error.message,
    });
  }
};
