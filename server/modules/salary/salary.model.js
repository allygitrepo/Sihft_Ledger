const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Employee = require("../employee/employee.model");

const Salary = sequelize.define("Salaries",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        employee_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Employee,
                key: 'id'
            }
        },
        month: { type: DataTypes.STRING, allowNull: false }, // e.g. "2025-03"
        total_days: { type: DataTypes.INTEGER, defaultValue: 0 },
        present_days: { type: DataTypes.INTEGER, defaultValue: 0 },
        absent_days: { type: DataTypes.INTEGER, defaultValue: 0 },
        overtime_hours: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        basic_pay: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
        overtime_pay: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        bonus: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        deductions: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        net_pay: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
        status: { type: DataTypes.ENUM('Unpaid', 'Paid'), defaultValue: 'Unpaid' }
    },
    {
        tableName: "calculated_salaries",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Salary;
