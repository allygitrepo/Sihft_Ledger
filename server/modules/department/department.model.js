const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Company = require("../company/company.model");

const Department = sequelize.define("Departments",
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
        department_name: { type: DataTypes.STRING, allowNull: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "departments",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Department;
