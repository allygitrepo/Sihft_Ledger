const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Department = require("../department/department.model");

const Designation = sequelize.define("Designations",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        department_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: Department,
                key: 'id'
            }
        },
        designation_name: { type: DataTypes.STRING, allowNull: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "designations",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Designation;
