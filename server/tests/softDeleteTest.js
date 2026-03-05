const axios = require("axios");
require("dotenv").config();

const BASE_URL = `http://localhost:${process.env.PORT || 3000}/shiftledger`;
let token = "";

const log = (msg, success = true) => {
    console.log(`${success ? "✔" : "✖"} ${msg}`);
};

async function runSoftDeleteTest() {
    try {
        console.log("--- Starting Cascading Soft Delete Tests ---");
        console.log(`Targeting: ${BASE_URL}\n`);

        // 0. Verify Server Connectivity
        try {
            const serverCheck = await axios.get(`http://localhost:${process.env.PORT || 3000}/`);
            console.log(`📡 Server Check: ${JSON.stringify(serverCheck.data)}`);
        } catch (e) {
            console.log(`✖ Server is not reachable at port ${process.env.PORT || 3000}. Error: ${e.message}`);
            process.exit(1);
        }

        // 1. Setup Data - Use a random phone to avoid unique constraint errors
        const randomPhone = Math.floor(1000000000 + Math.random() * 9000000000).toString();
        const testEmail = `delete_test_${randomPhone}@example.com`;

        // Register & Login
        try {
            await axios.post(`${BASE_URL}/user/register`, {
                owner_name: "Cleanup Tester",
                phone: randomPhone,
                email: testEmail,
                password: "password123"
            });
            const loginRes = await axios.post(`${BASE_URL}/user/login`, {
                phone: randomPhone,
                password: "password123"
            });
            token = loginRes.data.token;
        } catch (e) {
            console.log(`✖ Setup failed during Register/Login: ${e.response?.data?.message || e.message}`);
            process.exit(1);
        }

        const config = { headers: { Authorization: `Bearer ${token}` } };

        // Create Hierarchy
        const coRes = await axios.post(`${BASE_URL}/companies`, { company_name: "Delete Corp", industry_type: "Defense" }, config);
        const companyId = coRes.data.company.id;

        const deptRes = await axios.post(`${BASE_URL}/departments`, { company_id: companyId, department_name: "Archive Dept" }, config);
        const departmentId = deptRes.data.department.id;

        const desigRes = await axios.post(`${BASE_URL}/designations`, { department_id: departmentId, designation_name: "Ghost Manager" }, config);
        const designationId = desigRes.data.designation.id;

        const empRes = await axios.post(`${BASE_URL}/employees`, {
            company_id: companyId,
            department_id: departmentId,
            designation_id: designationId,
            first_name: "Casper",
            last_name: "Ghost",
            phone: (parseInt(randomPhone) + 1).toString(),
            email: `ghost_${randomPhone}@test.com`,
            join_date: "2025-01-01"
        }, config);
        const employeeId = empRes.data.employee.id;

        // Create Records
        await axios.post(`${BASE_URL}/attendance/clock-in`, { employee_id: employeeId, date: "2025-03-05", clock_in: "09:00:00" }, config);
        await axios.post(`${BASE_URL}/employee-salaries`, { emp_id: employeeId, basic_salary: 50000, allowances: 5000 }, config);
        const salRes = await axios.post(`${BASE_URL}/salaries/generate`, { employee_id: employeeId, month: "2025-03", basic_pay: 50000, present_days: 20 }, config);
        const salaryId = salRes.data.salary.id;

        log("Hierarchy setup completed.");

        // 2. Perform Soft Delete on Company
        console.log(`\n📡 Deleting Company (ID: ${companyId})...`);
        const delRes = await axios.delete(`${BASE_URL}/companies/${companyId}`, config);
        log(delRes.data.message);

        // 3. Verify Results
        console.log("\n--- Verification Phase ---");

        const checkStatus = async (endpoint, id, name) => {
            try {
                const res = await axios.get(`${BASE_URL}/${endpoint}/${id}`, config);
                // The response structure might vary slightly depending on the module
                const item = res.data[endpoint.split('/')[0].replace(/ies$/, 'y').replace(/s$/, '')] || res.data.employee || res.data.department || res.data.designation || res.data.company;

                if (item && item.status === false) {
                    log(`${name} soft deleted (status=false)`);
                    return true;
                } else {
                    log(`${name} STILL ACTIVE (status=${item?.status})`, false);
                    return false;
                }
            } catch (e) {
                log(`Error fetching ${name}: ${e.message}`, false);
                return false;
            }
        };

        let allPassed = true;

        allPassed &= await checkStatus("companies", companyId, "Company");
        allPassed &= await checkStatus("departments", departmentId, "Department");
        allPassed &= await checkStatus("designations", designationId, "Designation");
        allPassed &= await checkStatus("employees", employeeId, "Employee");

        if (allPassed) {
            console.log("\n✅ PASS -> cascade delete working");
        } else {
            console.log("\n❌ FAIL -> some records still active");
            process.exit(1);
        }

    } catch (error) {
        console.error("\n✖ Test Failed with error:");
        console.error(error.response?.data || error.message);
        process.exit(1);
    }
}

runSoftDeleteTest();
