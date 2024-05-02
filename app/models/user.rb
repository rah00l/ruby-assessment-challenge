class User < ApplicationRecord
	# Define enum for the 'kind' attribute
	enum kind: { student: 0, teacher: 1, student_teacher: 2 }

	# Define the association with enrollments
	has_many :enrollments, foreign_key: :user_id
	has_many :programs, through: :enrollments

	# Define associations for favorite teachers
	has_many :favorite_teachers_enrollments, -> { where(favorite: true) }, class_name: 'Enrollment'
	has_many :favorite_teachers, through: :favorite_teachers_enrollments, source: :teacher, class_name: 'User'

	# Define associations for classmates
	has_many :classmate_enrollments, through: :programs, source: :enrollments
	has_many :classmates, -> (user) { distinct.where.not(id: user.id) }, through: :classmate_enrollments, source: :user

	# Callback to validate kind update
	before_update :validate_kind_update

	private

	def validate_kind_update
		return unless kind_changed?

	  if student? && teaching.exists?
	    errors.add(:kind, "can not be student because is teaching in at least one program")
	    throw :abort
	  elsif teacher? && studying.exists?
	    errors.add(:kind, "can not be teacher because is studying in at least one program")
	    throw :abort
	  end
	end

	def teaching
	  Program.joins(:enrollments).where(enrollments: { teacher: self })
	end

	def studying
	  Program.joins(:enrollments).where(enrollments: { user: self })
	end
end
