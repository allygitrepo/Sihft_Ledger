const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Employee = require("../employee/employee.model");

const EmployeeSalary = sequelize.define("EmployeeSalary",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        emp_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Employee,
                key: 'id'
            }
        },
        basic_salary: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
        allowances: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        deductions: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        net_salary: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "employee_salary",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = EmployeeSalary;
