import ballerina/http;
import ballerina/time;
import ballerina/crypto;
import ballerina/log;

// -------------------- HTTP Listener --------------------
listener http:Listener adminListener = new(8086);

// -------------------- Mock Database --------------------
json[] mockAdmins = [];
json[] mockReports = [];

// -------------------- Utility Functions --------------------

// Hash password using SHA-256 (basic implementation for demonstration)
function hashPassword(string password) returns string {
    byte[] hashedBytes = crypto:hashSha256(password.toBytes());
    return hashedBytes.toBase16();
}

// Check if admin already exists by username or email
function adminExists(string username, string email) returns boolean {
    foreach json admin in mockAdmins {
        json|error adminUsername = admin.username;
        json|error adminEmail = admin.email;
        if adminUsername is json && adminEmail is json {
            string usernameStr = adminUsername is string ? adminUsername : "";
            string emailStr = adminEmail is string ? adminEmail : "";
            if usernameStr == username || emailStr == email {
                return true;
            }
        }
    }
    return false;
}

// Generate next admin ID
function getNextAdminId() returns int|error {
    int maxId = 0;
    foreach json admin in mockAdmins {
        json idJson = check admin.id;
        int id = check idJson.ensureType(int);
        if id > maxId {
            maxId = id;
        }
    }
    return maxId + 1;
}

// Initialize with default admin account if not exists
function initializeDefaultAdmin() {
    // Check if default admin already exists
    if !adminExists("admin", "admin@transpohub.com") {
        json defaultAdmin = {
            id: 1,
            username: "admin",
            email: "admin@transpohub.com",
            password_hash: hashPassword("admin123"),
            role: "super_admin",
            created_at: time:utcToString(time:utcNow())
        };
        mockAdmins.push(defaultAdmin);
        log:printInfo("Default admin account initialized successfully");
    } else {
        log:printInfo("Default admin account already exists");
    }
}

// Call initialization on service start
function init() {
    initializeDefaultAdmin();
}

//  Types 
type Admin record {
    int id;
    string username;
    string email;
    string password_hash;
    string role; // super_admin, manager, scheduler
    string created_at;
};

type AdminRequest record {
    string username;
    string email;
    string password_hash;
    string? role;
};

type LoginRequest record {
    string username;
    string password_hash;
};

type ServiceDisruption record {
    int id;
    string title;
    string description;
    string[] affected_routes;
    string severity; // low, medium, high, critical
    string status; // active, resolved
    string created_at;
    string? resolved_at;
};

type DisruptionRequest record {
    string title;
    string description;
    string[] affected_routes;
    string severity;
};

// Admin Service
service /admin on adminListener {

    // Admin login
    resource function post login(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        LoginRequest|error loginReq = payload.cloneWithType(LoginRequest);
        if loginReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Hash the provided password for comparison
        string hashedPassword = hashPassword(loginReq.password_hash);

        // Mock authentication
        foreach json admin in mockAdmins {
            if admin.username == loginReq.username && admin.password_hash == hashedPassword {
                http:Response response = new;
                response.setJsonPayload({
                    "status": "success",
                    "message": "Admin login successful",
                    "admin": {
                        "id": check admin.id,
                        "username": check admin.username,
                        "email": check admin.email,
                        "role": check admin.role
                    }
                });
                log:printInfo("Admin login successful for user: " + loginReq.username);
                return response;
            }
        }
        
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload({"status": "error", "message": "Invalid credentials"});
        log:printWarn("Failed login attempt for user: " + loginReq.username);
        return response;
    }

    // Create admin account (super admin only)
    resource function post createAdmin(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        AdminRequest|error adminReq = payload.cloneWithType(AdminRequest);
        if adminReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Check for duplicate admin
        if adminExists(adminReq.username, adminReq.email) {
            http:Response response = new;
            response.statusCode = 409;
            response.setJsonPayload({"status": "error", "message": "Admin with this username or email already exists"});
            return response;
        }

        // Generate new admin ID
        int id = check getNextAdminId();
        
        // Set default role if not provided
        string role = adminReq.role ?: "manager";
        
        // Create new admin with hashed password
        json newAdmin = {
            id: id,
            username: adminReq.username,
            email: adminReq.email,
            password_hash: hashPassword(adminReq.password_hash),
            role: role,
            created_at: time:utcToString(time:utcNow())
        };
        
        mockAdmins.push(newAdmin);
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Admin account created successfully",
            "admin_id": id,
            "username": adminReq.username,
            "role": role
        });
        log:printInfo("New admin account created: " + adminReq.username + " with role: " + role);
        return response;
    }

    // Get all admin accounts (super admin only)
    resource function get admins() returns http:Response|error {
        // Remove sensitive password information
        json[] safeAdmins = [];
        foreach json admin in mockAdmins {
            map<json> safeAdmin = <map<json>>admin.clone();
            _ = safeAdmin.remove("password_hash");
            safeAdmins.push(safeAdmin);
        }
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "admins": safeAdmins,
            "total_count": safeAdmins.length()
        });
        return response;
    }

    // Update admin role (super admin only)
    resource function put admins/[int adminId]/role(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        json roleJson = check payload.role;
        string newRole = check roleJson.ensureType(string);
        
        // Validate role
        if newRole != "super_admin" && newRole != "manager" && newRole != "scheduler" {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid role. Must be super_admin, manager, or scheduler"});
            return response;
        }

        boolean found = false;
        foreach int i in 0 ..< mockAdmins.length() {
            json admin = mockAdmins[i];
            if admin.id == adminId {
                map<json> updatedAdmin = <map<json>>admin.clone();
                updatedAdmin["role"] = newRole;
                mockAdmins[i] = updatedAdmin;
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success", 
                "message": "Admin role updated successfully"
            });
            log:printInfo("Admin role updated for ID: " + adminId.toString() + " to role: " + newRole);
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Admin not found"
            });
        }
        
        return response;
    }

    // Delete admin account (super admin only)
    resource function delete admins/[int adminId]() returns http:Response|error {
        boolean found = false;
        string deletedUsername = "";
        
        foreach int i in 0 ..< mockAdmins.length() {
            json admin = mockAdmins[i];
            if admin.id == adminId {
                // Prevent deletion of default admin
                if admin.username == "admin" {
                    http:Response response = new;
                    response.statusCode = 403;
                    response.setJsonPayload({
                        "status": "error", 
                        "message": "Cannot delete default admin account"
                    });
                    return response;
                }
                
                deletedUsername = check admin.username.ensureType(string);
                _ = mockAdmins.remove(i);
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success",
                "message": "Admin account deleted successfully"
            });
            log:printInfo("Admin account deleted: " + deletedUsername);
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Admin not found"
            });
        }
        
        return response;
    }

    // Change admin password
    resource function put admins/[int adminId]/password(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        json oldPasswordJson = check payload.old_password;
        json newPasswordJson = check payload.new_password;
        string oldPassword = check oldPasswordJson.ensureType(string);
        string newPassword = check newPasswordJson.ensureType(string);

        boolean found = false;
        string hashedOldPassword = hashPassword(oldPassword);
        
        foreach int i in 0 ..< mockAdmins.length() {
            json admin = mockAdmins[i];
            if admin.id == adminId {
                if admin.password_hash == hashedOldPassword {
                    map<json> updatedAdmin = <map<json>>admin.clone();
                    updatedAdmin["password_hash"] = hashPassword(newPassword);
                    mockAdmins[i] = updatedAdmin;
                    found = true;
                    break;
                } else {
                    http:Response response = new;
                    response.statusCode = 401;
                    response.setJsonPayload({
                        "status": "error", 
                        "message": "Current password is incorrect"
                    });
                    return response;
                }
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success",
                "message": "Password updated successfully"
            });
            log:printInfo("Password updated for admin ID: " + adminId.toString());
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Admin not found"
            });
        }
        
        return response;
    }

    // Get system dashboard statistics
    resource function get dashboard() returns http:Response|error {
        // Mock dashboard data
        json dashboardStats = {
            total_passengers: 150,
            total_routes: 25,
            active_tickets: 75,
            total_revenue: 12500.50,
            tickets_sold_today: 32,
            system_alerts: 3,
            top_routes: [
                {"route": "Windhoek Central - Katutura", "tickets_sold": 45},
                {"route": "Windhoek Central - Olympia", "tickets_sold": 38},
                {"route": "Katutura - Wanaheda", "tickets_sold": 29}
            ]
        };
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "dashboard": dashboardStats
        });
        return response;
    }

    // Create service disruption announcement
    resource function post disruptions(http:Request req) returns http:Response|error {
        json payload = check req.getJsonPayload();
        
        DisruptionRequest|error disruptionReq = payload.cloneWithType(DisruptionRequest);
        if disruptionReq is error {
            http:Response response = new;
            response.statusCode = 400;
            response.setJsonPayload({"status": "error", "message": "Invalid request format"});
            return response;
        }

        // Mock disruption creation
        int id = mockReports.length() + 1;
        
        json newDisruption = {
            id: id,
            title: disruptionReq.title,
            description: disruptionReq.description,
            affected_routes: disruptionReq.affected_routes,
            severity: disruptionReq.severity,
            status: "active",
            created_at: "2025-10-05T00:00:00Z",
            resolved_at: ()
        };
        
        mockReports.push(newDisruption);
        
        // TODO: Send notification to affected passengers via Kafka
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "message": "Service disruption created",
            "disruption_id": id
        });
        return response;
    }

    // Get all service disruptions
    resource function get disruptions() returns http:Response|error {
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "disruptions": mockReports
        });
        return response;
    }

    // Resolve service disruption
    resource function put disruptions/[int disruptionId]/resolve() returns http:Response|error {
        boolean found = false;
        
        foreach int i in 0 ..< mockReports.length() {
            json disruption = mockReports[i];
            if disruption.id == disruptionId {
                map<json> updatedDisruption = <map<json>>disruption.clone();
                updatedDisruption["status"] = "resolved";
                updatedDisruption["resolved_at"] = "2025-10-05T00:00:00Z";
                mockReports[i] = updatedDisruption;
                found = true;
                break;
            }
        }
        
        http:Response response = new;
        if found {
            response.setJsonPayload({
                "status": "success", 
                "message": "Service disruption resolved"
            });
        } else {
            response.statusCode = 404;
            response.setJsonPayload({
                "status": "error", 
                "message": "Service disruption not found"
            });
        }
        
        return response;
    }

    // Generate sales report
    resource function get reports/sales() returns http:Response|error {
        // Mock sales report data
        json salesReport = {
            report_period: "Last 30 days",
            total_revenue: 45670.25,
            total_tickets_sold: 892,
            avg_ticket_price: 51.20,
            sales_by_route: [
                {"route": "Windhoek Central - Katutura", "revenue": 15450.00, "tickets": 302},
                {"route": "Windhoek Central - Olympia", "revenue": 12800.50, "tickets": 256},
                {"route": "Katutura - Wanaheda", "revenue": 8920.25, "tickets": 178}
            ],
            sales_by_ticket_type: [
                {"type": "single_ride", "count": 654, "revenue": 33470.00},
                {"type": "multi_ride", "count": 156, "revenue": 7980.25},
                {"type": "monthly_pass", "count": 82, "revenue": 4220.00}
            ]
        };
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "report": salesReport
        });
        return response;
    }

    // Generate passenger traffic report
    resource function get reports/traffic() returns http:Response|error {
        // Mock traffic report data
        json trafficReport = {
            report_period: "Last 7 days",
            total_passengers: 1245,
            peak_hours: [
                {"hour": "07:00-08:00", "passenger_count": 156},
                {"hour": "08:00-09:00", "passenger_count": 203},
                {"hour": "17:00-18:00", "passenger_count": 189},
                {"hour": "18:00-19:00", "passenger_count": 167}
            ],
            busiest_routes: [
                {"route": "Windhoek Central - Katutura", "daily_avg": 78},
                {"route": "Windhoek Central - Olympia", "daily_avg": 65},
                {"route": "Katutura - Wanaheda", "daily_avg": 42}
            ],
            occupancy_rates: {
                buses: "73%",
                trains: "68%"
            }
        };
        
        http:Response response = new;
        response.setJsonPayload({
            "status": "success", 
            "report": trafficReport
        });
        return response;
    }
}