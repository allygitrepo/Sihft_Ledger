const OvertimeSlot = require("./overtime_slots.model");

const overtimeSlotController = {
    create: async (req, res) => {
        try {
            const { company_id, slot_name, start_time, end_time, rate_multiplier } = req.body;

            if (!company_id || !slot_name || !start_time || !end_time) {
                return res.status(400).json({ message: "Required fields are missing" });
            }

            const slot = await OvertimeSlot.create({
                company_id,
                slot_name,
                start_time,
                end_time,
                rate_multiplier
            });

            return res.status(201).json({ message: "Overtime slot created successfully", slot });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getAll: async (req, res) => {
        try {
            const { company_id } = req.query;
            const whereClause = company_id ? { company_id } : {};
            const slots = await OvertimeSlot.findAll({ where: whereClause });
            return res.status(200).json({ slots });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const slot = await OvertimeSlot.findByPk(id);

            if (!slot) {
                return res.status(404).json({ message: "Overtime slot not found" });
            }

            return res.status(200).json({ slot });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    update: async (req, res) => {
        try {
            const { id } = req.params;
            const updates = req.body;

            const slot = await OvertimeSlot.findByPk(id);

            if (!slot) {
                return res.status(404).json({ message: "Overtime slot not found" });
            }

            await slot.update(updates);

            return res.status(200).json({ message: "Overtime slot updated successfully", slot });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const slot = await OvertimeSlot.findByPk(id);

            if (!slot) {
                return res.status(404).json({ message: "Overtime slot not found" });
            }

            await slot.destroy();
            return res.status(200).json({ message: "Overtime slot deleted successfully" });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = overtimeSlotController;
