const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Company = require("../company/company.model");

const Salary = sequelize.define("SalaryConfiguration",
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
        salary_calculation_method: { 
            type: DataTypes.ENUM('Hour-wise', 'Day-wise'), 
            allowNull: false,
            defaultValue: 'Hour-wise'
        },
        hours_per_day: { 
            type: DataTypes.DECIMAL(4, 2), 
            allowNull: false, 
            defaultValue: 8.0 
        },
        days_per_month: { 
            type: DataTypes.INTEGER, 
            allowNull: false, 
            defaultValue: 26 
        },
        salary_input_type: { 
            type: DataTypes.ENUM('Monthly', 'Daily', 'Hourly'), 
            allowNull: false,
            defaultValue: 'Monthly'
        },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "salary_configurations",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Salary;
