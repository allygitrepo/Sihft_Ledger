const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Company = require("../company/company.model");

const OvertimeSlot = sequelize.define("OvertimeSlots",
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
        slot_name: { type: DataTypes.STRING, allowNull: false },
        start_time: { type: DataTypes.TIME, allowNull: false },
        end_time: { type: DataTypes.TIME, allowNull: false },
        rate_multiplier: { type: DataTypes.DECIMAL(3, 2), defaultValue: 1.00 },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "overtime_slots",
        timestamps: true,
        createdAt: 'created_at',
        updatedAt: 'updated_at'
    }
);

module.exports = OvertimeSlot;
