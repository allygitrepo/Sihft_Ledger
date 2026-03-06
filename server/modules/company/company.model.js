const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const User = require("../user/user.model");

const Company = sequelize.define("Companies",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        owner_id: {
            type: DataTypes.INTEGER,
            allowNull: false,
            references: {
                model: User,
                key: 'id'
            }
        },
        company_name: { type: DataTypes.STRING, allowNull: false },
        industry_type: { type: DataTypes.STRING, allowNull: false },
        address: { type: DataTypes.TEXT, allowNull: true },
        company_logo: { type: DataTypes.TEXT, allowNull: true },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "companies",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = Company;
