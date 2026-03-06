const axios = require("axios");
require("dotenv").config();

const BASE_URL = `http://localhost:${process.env.PORT || 3000}/shiftledger`;
let token = "";
let companyId = "";
let departmentId = "";
let designationId = "";
let employeeId = "";
let salaryId = "";

const randomPhone = Math.floor(1000000000 + Math.random() * 9000000000).toString();
const testEmail = `test_${randomPhone}@example.com`;

const log = (msg, success = true) => {
    console.log(`${success ? "✔" : "✖"} ${msg}`);
};

async function runTests() {
    try {
        console.log("--- Starting ShiftLedger API Tests ---");
        console.log(`Using test phone: ${randomPhone}`);
        console.log(`Targeting: ${BASE_URL}\n`);

        // 0. Verify Server Connectivity
        try {
            const serverCheck = await axios.get(`http://localhost:${process.env.PORT || 3000}/`);
            console.log(`✔ Server Check: ${JSON.stringify(serverCheck.data)}`);
        } catch (e) {
            console.log(`✖ Server is not reachable at port ${process.env.PORT || 3000}. Is the server running?`);
            process.exit(1);
        }

        // 1. User Register & Login
        const registerUrl = `${BASE_URL}/user/register`;
        try {
            console.log(`📡 Sending POST to: ${registerUrl}`);
            await axios.post(registerUrl, {
                owner_name: "Test Owner",
                phone: randomPhone,
                email: testEmail,
                password: "password123"
            });
            log("User REGISTER passed");
        } catch (e) {
            log(`User REGISTER failed: ${e.response?.status} - ${e.response?.data?.message || e.message}`, false);
            console.log(`Full URL attempted: ${registerUrl}`);
            process.exit(1);
        }

        try {
            const loginRes = await axios.post(`${BASE_URL}/user/login`, {
                phone: randomPhone,
                password: "password123"
            });
            token = loginRes.data.token;
            log("User LOGIN passed");
        } catch (e) {
            log(`User LOGIN failed: ${e.response?.data?.message || e.message}`, false);
            process.exit(1);
        }

        const config = { headers: { Authorization: `Bearer ${token}` } };

        // 2. Company CRUD
        try {
            const coRes = await axios.post(`${BASE_URL}/companies`, {
                company_name: "Test Company Corp",
                industry_type: "Technology",
                address: "Silicon Valley"
            }, config);
            companyId = coRes.data.company.id;
            log("Company CREATE passed");
        } catch (e) {
            log(`Company CREATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        try {
            await axios.get(`${BASE_URL}/companies/${companyId}`, config);
            log("Company READ (Get by ID) passed");
        } catch (e) {
            log(`Company READ failed: ${e.response?.data?.message || e.message}`, false);
        }

        try {
            await axios.put(`${BASE_URL}/companies/${companyId}`, { company_name: "Updated Corp" }, config);
            log("Company UPDATE passed");
        } catch (e) {
            log(`Company UPDATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 3. Department CRUD
        try {
            const deptRes = await axios.post(`${BASE_URL}/departments`, {
                company_id: companyId,
                department_name: "Operations"
            }, config);
            departmentId = deptRes.data.department.id;
            log("Department CREATE passed");
        } catch (e) {
            log(`Department CREATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 4. Designation CRUD
        try {
            const desigRes = await axios.post(`${BASE_URL}/designations`, {
                department_id: departmentId,
                designation_name: "Lead Manager"
            }, config);
            designationId = desigRes.data.designation.id;
            log("Designation CREATE passed");
        } catch (e) {
            log(`Designation CREATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 5. Employee CRUD
        try {
            const empRes = await axios.post(`${BASE_URL}/employees`, {
                company_id: companyId,
                department_id: departmentId,
                designation_id: designationId,
                first_name: "John",
                last_name: "Doe",
                phone: Math.floor(1000000000 + Math.random() * 9000000000).toString(),
                email: `john_${Date.now()}@test.com`,
                join_date: "2025-01-01"
            }, config);
            employeeId = empRes.data.employee.id;
            log("Employee CREATE passed");
        } catch (e) {
            log(`Employee CREATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 6. Attendance CRUD
        try {
            await axios.post(`${BASE_URL}/attendance/clock-in`, {
                employee_id: employeeId,
                date: "2025-03-05",
                clock_in: "09:00:00"
            }, config);
            log("Attendance CLOCK-IN passed");
        } catch (e) {
            log(`Attendance CLOCK-IN failed: ${e.response?.data?.message || e.message}`, false);
        }

        try {
            await axios.post(`${BASE_URL}/attendance/clock-out`, {
                employee_id: employeeId,
                date: "2025-03-05",
                clock_out: "18:00:00"
            }, config);
            log("Attendance CLOCK-OUT passed");
        } catch (e) {
            log(`Attendance CLOCK-OUT failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 7. Salary & Overtime Configuration
        try {
            await axios.post(`${BASE_URL}/employee-salaries`, {
                emp_id: employeeId,
                basic_salary: 45000,
                allowances: 4000
            }, config);
            log("Employee Salary Config passed");
        } catch (e) {
            log(`Employee Salary Config failed: ${e.response?.data?.message || e.message}`, false);
        }

        try {
            await axios.post(`${BASE_URL}/overtime-slots`, {
                company_id: companyId,
                slot_name: "Night Shift",
                start_time: "20:00:00",
                end_time: "23:00:00",
                rate_multiplier: 1.5
            }, config);
            log("Overtime Slot CREATE passed");
        } catch (e) {
            log(`Overtime Slot CREATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        // 8. Monthly Salary Generation & Payment
        try {
            const salRes = await axios.post(`${BASE_URL}/salaries/generate`, {
                employee_id: employeeId,
                month: "2025-03",
                basic_pay: 45000,
                present_days: 20
            }, config);
            salaryId = salRes.data.salary.id;
            log("Salary GENERATE passed");
        } catch (e) {
            log(`Salary GENERATE failed: ${e.response?.data?.message || e.message}`, false);
        }

        try {
            await axios.put(`${BASE_URL}/salaries/pay/${salaryId}`, {}, config);
            log("Salary MARK AS PAID passed");
        } catch (e) {
            log(`Salary MARK AS PAID failed: ${e.response?.data?.message || e.message}`, false);
        }

        console.log("\n--- All ShiftLedger Tests Completed Successfully ---");
    } catch (error) {
        console.error("\n✖ Unexpected error:");
        console.error(error.message);
        process.exit(1);
    }
}

runTests();

