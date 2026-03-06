const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Company = require("../company/company.model");
const Department = require("../department/department.model");
const Designation = require("../designation/designation.model");

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
        first_name: { type: DataTypes.STRING, allowNull: false },
        last_name: { type: DataTypes.STRING, allowNull: false },
        phone: { type: DataTypes.STRING, allowNull: false, unique: true },
        email: { type: DataTypes.STRING, allowNull: true, unique: true },
        join_date: { type: DataTypes.DATEONLY, allowNull: false },
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
