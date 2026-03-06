const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Company = require("../company/company.model");
const Department = require("../department/department.model");
const Designation = require("../designation/designation.model");
const Salary = require("../salary/salary.model"); // This is SalaryConfiguration

const Employee = sequelize.define("Employees",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        company_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Company,
                key: 'id'
            }
        },
        department_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Department,
                key: 'id'
            }
        },
        designation_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Designation,
                key: 'id'
            }
        },
        salary_config_id: {
            type: DataTypes.INTEGER,
            allowNull: true,
            references: {
                model: Salary,
                key: 'id'
            }
        },
        full_name: { type: DataTypes.STRING, allowNull: false, defaultValue: '' },
        phone: { type: DataTypes.STRING, allowNull: false, unique: true },
        employee_code: { type: DataTypes.STRING, allowNull: true, unique: true },
        monthly_salary: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0.00 },
        join_date: { 
            type: DataTypes.DATEONLY, 
            allowNull: false, 
            defaultValue: DataTypes.NOW 
        },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "employees",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Employee;
